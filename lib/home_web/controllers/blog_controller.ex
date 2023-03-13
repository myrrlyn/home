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
    |> build(params, :index, "blog/index.md")
  end

  def atom(conn, _params) do
    conn
    |> put_resp_content_type("application/atom+xml")
    |> render(:atom, articles: get_articles())
  end

  @doc "Render an RSS feed"
  def rss(conn, _params) do
    conn
    |> put_resp_content_type("application/rss+xml")
    |> render(:rss, articles: get_articles())
  end

  # Render a group index page
  def category(conn, %{"category" => group} = params) do
    src_path = ["blog", group, "index.md"] |> Path.join()

    index = src_path |> Home.PageCache.cached()
    category = grouped_by_category(group) |> List.first()

    case {index, category} do
      {{:error, %Home.Page.NotFoundException{}}, nil} ->
        conn
        |> assign(:category, group)
        |> error(404, :"invalid-category", "Invalid Category")

      {{:error, %Home.Page.NotFoundException{}}, {name, slug, pages}} ->
        conn
        |> merge_assigns(name: name, slug: slug, pages: pages)
        |> error(200, :"missing-category", name)

      {{:ok, %Home.Page{meta: meta}}, {_, _, pages}} ->
        if meta.published || Application.get_env(:home, :show_drafts) do
          conn
          |> assign(:pages, pages)
          |> build(params, :category, src_path)
        else
          conn
          |> assign(:category, group)
          |> error(404, :"invalid-category", "Invalid Category")
        end
    end
  end

  # Map categorized pages correctly.
  def article(conn, %{"category" => group, "article" => page} = params) do
    case url_to_path(group, page) do
      nil ->
        conn |> error(404, :"missing-article", "Missing Article")

      path ->
        conn |> build(params, :page, path)
    end
  end

  # Map nested resources correctly.
  def resource(
        conn,
        %{"category" => group, "article" => folder, "resource" => resource} = _params
      ) do
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

  def build(conn, _params, template) do
    conn
    |> render(
      template,
      flavor: "app",
      classes: ["blog"],
      gravatar: Home.Page.gravatar("self@myrrlyn.dev"),
      navtree: fn -> navtree(conn.request_path) end,
      scope: @root
    )
  end

  def build(conn, params, template, src_path) do
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
        |> send_resp(301, "Moved to #{HomeWeb.Endpoint.url()}#{redirect}")

      {:error, :einval} ->
        case src_path |> Home.PageCache.cached() do
          {:ok, page} ->
            conn
            |> merge_assigns(
              page: page,
              src_path: src_path,
              banner: Home.Banners.select_or_random(page.meta),
              tab_title: page.meta.title,
              tab_suffix:
                case page.meta.title do
                  "Insufficiently Magical" -> nil
                  _ -> " · Insufficiently Magical"
                end
            )
            |> build(params, template)

          {:error, _err} ->
            conn |> error(500, :"invalid-article", "Broken Article")
        end
    end
  end

  def error(conn, status, template, title) do
    conn
    |> put_status(status)
    |> put_view(HomeWeb.ErrorHTML)
    |> render(
      template,
      flavor: "app",
      gravatar: Home.Page.gravatar("self@myrrlyn.dev"),
      classes: ["blog"],
      navtree: &navtree/0,
      page: nil,
      tab_title: title,
      tab_suffix: " · Insufficiently Magical",
      page_title: title,
      scope: @root
    )
  end

  @doc """
  Select all articles in the blog system, clustered by their category. If a
  category or list of categories are provided, this returns only that subset.

  Articles are already sorted into category folders on the filesystem, so this
  function merely loads the contents of each category folder and keeps them
  clustered together, rather than returning one mixed collection like
  `get_articles` does.

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
    |> Task.async_stream(fn dir ->
      {dir,
       dir
       |> src_paths()
       |> get_articles()}
    end)
    |> Stream.filter(fn {status, _} -> status == :ok end)
    |> Stream.map(fn {:ok, {slug, pages}} ->
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
      HomeWeb.Nav.Entry.new("📚 <small>(Blog index)</small>", @root, "dr-xr-xr-x"),
      HomeWeb.Nav.Entry.new("🏡 <small>(Site index)</small>", "/", "dr-xr-xr-x")
    ]
    |> Stream.concat(HomeWeb.Nav.make_listing(get_articles(), current))
  end

  def page_listing() do
    get_articles()
    |> Stream.map(fn {url, meta} ->
      {meta.title, url,
       if meta.published do
         Timex.format!(meta.date, "{ISOdate}")
       else
         "DRAFT PAGE"
       end}
    end)
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
    # Discard any invalid entries. That’s my problem, not the viewer’s problem.
    |> Stream.filter(fn {res, _} -> res == :ok end)
    # Translate filepath to URL and drop the full page for just metadata
    |> Stream.map(fn {:ok, {path, page}} -> {path |> path_to_url(), page.meta} end)
    # If we are not in :dev, discard unpublished entries
    |> (fn seq ->
          if Application.get_env(:home, :show_drafts),
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
