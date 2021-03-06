defmodule HomeWeb.BlogController do
  use HomeWeb, :controller
  require Logger

  @root "/blog"
  @dir ["priv", "pages", @root] |> Path.join()

  def index(conn, params) do
    groups =
      grouped_by_category()
      |> Stream.reject(fn {_, _, pages} -> pages == [] end)
      |> Stream.map(fn {name, slug, pages} ->
        count = pages |> Enum.count()

        case "blog/#{slug}/index.md" |> Home.PageCache.cached() do
          {:ok, %Home.Page{meta: meta}} -> {meta.title, slug, count, meta.summary}
          {:error, _} -> {name, slug, count, nil}
        end
      end)

    conn
    |> assign(:groups, groups)
    |> build(params, "index.html", @root, "blog/index.md")
  end

  @doc "Render an RSS feed"
  def feed(conn, _params) do
    conn
    |> put_resp_content_type("application/rss+xml")
    |> render("rss.xml", layout: nil, articles: get_articles())
  end

  def page(conn, %{"path" => [group]} = params) do
    req_url = [@root, group] |> Path.join()
    src_path = ["blog", group, "index.md"] |> Path.join()

    index = src_path |> Home.PageCache.cached()
    category = grouped_by_category(group) |> List.first()

    case {index, category} do
      {{:error, %Home.Page.NotFoundException{}}, nil} ->
        conn
        |> assign(:category, group)
        |> error(404, "invalid-category.html", req_url, "Invalid category")

      {{:error, %Home.Page.NotFoundException{}}, {name, slug, pages}} ->
        conn
        |> assign(:name, name)
        |> assign(:slug, slug)
        |> assign(:meta, %Home.Meta{title: name})
        |> assign(:pages, pages)
        |> assign(:banner, "banners/2017-01-28T08-50-37.jpg")
        |> error(200, "missing-category.html", @root, name)

      {{:ok, %Home.Page{meta: meta}}, {_, _, pages}} ->
        if meta.published || Mix.env() == :dev do
          conn
          |> assign(:pages, pages)
          |> build(params, "category.html", req_url, src_path)
        else
          conn
          |> assign(:category, group)
          |> error(404, "invalid-category.html", req_url, "Invalid category")
        end
    end
  end

  # Map categorized pages correctly.
  def page(conn, %{"path" => [group, page]} = params) do
    req_url = [@root, group, page] |> Path.join()

    case url_to_path(group, page) do
      nil ->
        conn |> error(404, "missing-article.html", req_url, "Missing article")

      path ->
        conn |> build(params, "page.html", req_url, path)
    end
  end

  # Map nested resources correctly.
  def page(conn, %{"path" => [group, folder, resource]} = _params) do
    path = [@dir, group, folder, resource] |> Path.join()

    if path |> File.regular?() do
      conn
      |> put_resp_content_type(resource |> MIME.from_path())
      |> Home.Etag.cache_send_file(200, path)
    else
      conn |> send_resp(404, "Resource not found")
    end
  end

  def page(conn, params), do: conn |> HomeWeb.PageController.error(404, params)

  def build(conn, _params, template, req_url) do
    conn
    |> PhoenixETag.render_if_stale(
      template,
      flavor: "app",
      classes: ["blog"],
      gravatar: Home.Page.gravatar("self@myrrlyn.dev"),
      navtree: fn -> __MODULE__.navtree(req_url) end,
      scope: @root,
      req_url: req_url
    )
  end

  def build(conn, params, template, req_url, src_path) do
    case ["priv", "pages", src_path] |> Path.join() |> File.read_link() do
      {:ok, redirect} ->
        Logger.notice("Accessed a deprecated path")
        dir = src_path |> Path.dirname()

        redirect =
          [dir, redirect]
          |> Path.join()
          |> Path.expand("/")
          |> Path.relative_to("/")
          |> path_to_url()

        conn
        |> put_resp_header("location", redirect)
        |> send_resp(301, "Moved to https://myrrlyn.net#{redirect}")

      {:error, :einval} ->
        case src_path |> Home.PageCache.cached() do
          {:ok, page} ->
            banner = page.meta.props |> Map.get("banner", "2017-01-28T08-50-37.jpg")

            conn
            |> assign(:banner, ["banners", banner] |> Path.join())
            |> assign(:page, page)
            |> assign(:meta, page.meta)
            |> assign(:src_path, src_path)
            |> build(params, template, req_url)

          {:error, _err} ->
            conn |> error(500, "invalid-article.html", req_url, "Broken article")
        end
    end
  end

  def error(conn, status, template, req_url, title) do
    conn
    |> put_status(status)
    |> put_view(HomeWeb.ErrorView)
    |> render(
      template,
      flavor: "app",
      banner: ["banners", "2017-01-28T08-50-37.jpg"] |> Path.join(),
      gravatar: Home.Page.gravatar("self@myrrlyn.dev"),
      classes: ["blog"],
      navtree: fn -> navtree() end,
      page: nil,
      meta: %Home.Meta{title: title},
      scope: @root,
      req_url: req_url
    )
  end

  @doc """
  Select all articles in the blog system, clustered by their category. If a
  category or list of categories are provided, this returns only that subset.

  Articles are already sorted into category folders on the filesystem, so this
  function merely loads the contents of each category folder and keeps them
  clustered together, rather than returning one mixed collection like
  `page_listing` does.

  ## Parameters

  - `categories`: A string or list of strings, each of which names a category
    directory in the blog root.

  ## Returns

  A list of `{name, slug, [{url, meta}]}` for each category slug selected.

  - `name` is a display name suitable for rendering to the user
  - `slug` is the filesystem and URL component
  - `[{url, meta}]` is the list of full URLs and article metadata for each
    article in the category.
  """
  @spec grouped_by_category(String.t() | [String.t()]) :: [
          {String.t(), Path.t(), [{Path.t(), Home.Meta.t()}]}
        ]
  def grouped_by_category(categories \\ []) do
    @dir
    |> File.ls!()
    |> (fn dirs ->
          if categories != [] do
            dirs |> Stream.filter(&(&1 in List.wrap(categories)))
          else
            dirs
          end
        end).()
    |> Stream.filter(&([@dir, &1] |> Path.join() |> File.dir?()))
    |> Enum.map(fn dir ->
      Task.async(fn ->
        dir
        |> src_paths()
        |> get_articles()
        |> (fn pages -> {dir, pages} end).()
      end)
    end)
    |> Stream.map(&Task.await/1)
    |> Stream.map(fn {slug, pages} ->
      name = slug |> String.split("-") |> Stream.map(&String.capitalize/1) |> Enum.join(" ")

      {case name do
         "Misc" -> "General"
         n -> n
       end, slug, pages}
    end)
    |> Enum.sort_by(fn {_, _, list} -> list |> length end, :desc)
  end

  def navtree(current \\ nil) do
    [
      {"<code>.</code> <small>(Blog index)</small>", "#{@root}", "dr-x"},
      {"<code>..</code> <small>(Site index)</small>", "/", "dr-x"}
    ] ++ page_listing(current)
  end

  @doc """
  Lists all articles in the blog system, irrespective of category and sorted by
  date.
  """
  @spec page_listing(Path.t() | nil) :: [{String.t(), Path.t(), String.t()}]
  def page_listing(current \\ nil) do
    get_articles()
    |> Stream.map(fn {url, meta} ->
      {"<span class=\"title\">" <> meta.title <> "</span>", url,
       if meta.published do
         Timex.format!(meta.date, "{ISOdate}")
       else
         "DRAFT PAGE"
       end}
    end)
    |> Stream.map(fn {name, url, date} ->
      name =
        if url == current do
          "???? " <> name <> " ????"
        else
          name
        end

      {name, url, date}
    end)
    |> Enum.to_list()
  end

  @doc """
  Fetches a set of articles from the blog system.

  By default, this loads all articles in the blog; however, you may stream path
  entries (rooted beneath `priv/pages/`) into this to limit the fetch to the
  provided paths.

  ## Parameters

  - `paths`: A set of paths, implicitly rooted in `priv/pages/`, to load.
    Defaults to `blog/*/*.md`.

  ## Returns

  A list of `{url, metadata}` for each article fetched. The articles are all
  loaded into the `Home.PageCache`, and can be accessed by the same paths passed
  into this.
  """
  @spec get_articles(Stream.t()) :: [{Path.t(), Home.Meta.t()}]
  def get_articles(paths \\ src_paths()) do
    paths
    # Do not include filesystem-powered redirects.
    |> Stream.reject(fn p -> ["priv", "pages", p] |> Path.join() |> Home.symlink?() end)
    # Kick off a cache load
    |> Home.PageCache.cached_many()
    # Discard any invalid entries. That???s my problem, not the viewer???s problem.
    |> Stream.filter(fn {res, _} -> res == :ok end)
    # Translate filepath to URL and drop the full page for just metadata
    |> Stream.map(fn {:ok, {path, page}} -> {path |> path_to_url(), page.meta} end)
    # If we are not in :dev, discard unpublished entries
    |> (fn seq ->
          if Mix.env() == :dev,
            do: seq,
            else: seq |> Stream.filter(fn {_, meta} -> meta.published end)
        end).()
    # And sort by date
    |> Enum.sort_by(fn {_, meta} -> meta.date end, {:desc, DateTime})
  end

  @doc """
  Given a group and article name, finds the path (with datestamp) of the source
  file.
  """
  @spec url_to_path(Path.t(), Path.t()) :: Path.t() | nil
  def url_to_path(group, name) do
    src_paths(group)
    |> Enum.find(fn path ->
      path |> path_to_url() == [@root, group, name] |> Path.join()
    end)
  end

  @doc """
  Given a filepath, constructs the corresponding site URL.
  """
  @spec path_to_url(Path.t()) :: Path.t()
  def path_to_url(path) do
    case path |> Path.rootname() |> Path.split() do
      ["blog", group, filename] ->
        [_y, _m, _d, name] = filename |> String.split("-", parts: 4)
        [@root, group, name] |> Path.join()

      ["blog", group] ->
        [@root, group] |> Path.join()
    end
  end

  @doc """
  Produces `Home.PageCache` lookup keys for all articles in the blog system. May
  be restricted to a single category by providing an argument naming the
  category directory on disk.
  """
  @spec src_paths(Path.t()) :: Enumerable.t()
  def src_paths(category \\ "*") do
    [@dir, category, "*.md"]
    |> Path.join()
    |> Path.wildcard()
    # Discard index files
    |> Stream.reject(fn p -> p |> Path.basename() == "index.md" end)
    # Discard subdirectories (should not exist with a .md suffix anyway)
    |> Stream.filter(&File.regular?/1)
    # Drop the content-directory prefix
    |> Stream.map(&(&1 |> Path.relative_to("priv/pages")))
  end
end
