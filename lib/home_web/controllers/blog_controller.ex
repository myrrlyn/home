defmodule HomeWeb.BlogController do
  use HomeWeb, :controller
  require Logger

  @root "/blog"
  @dir ["priv", "pages", @root] |> Path.join()

  def index(conn, params) do
    conn
    |> build(params, "index.html", @root, "blog/index.md")
  end

  @doc "Render an RSS feed"
  def feed(conn, _params) do
    conn
    |> put_resp_content_type("application/rss+xml")
    |> render("rss.xml", layout: nil, articles: get_articles())
  end

  def page(conn, %{"path" => [_group]}) do
    conn |> error(500, "invalid-category.html", nil, "Unimplemented feature")
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

  def build(conn, _params, template, req_url, src_path) do
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
            |> PhoenixETag.render_if_stale(template,
              flavor: "app",
              banner: ["banners", banner] |> Path.join(),
              classes: ["blog"],
              page: page,
              meta: page.meta,
              gravatar: Home.Page.gravatar("self@myrrlyn.dev"),
              navtree: fn -> __MODULE__.navtree(req_url) end,
              scope: @root,
              req_url: req_url,
              src_path: src_path
            )

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

  def grouped_by_category() do
    get_articles()
    |> Enum.group_by(fn {url, _} ->
      ["/", "blog", group, _] = url |> Path.split()
      {group |> String.split("-") |> Stream.map(&String.capitalize/1) |> Enum.join(" "), group}
    end)
    |> Enum.map(fn {{name, ident}, list} ->
      name =
        case name do
          "Misc" -> "General"
          n -> n
        end

      {name, ident, list}
    end)
    |> Enum.sort_by(fn {_, _, list} -> list |> length end, :desc)
  end

  def check_draft(conn, page) do
    case page.meta.published do
      true -> conn
      _ -> raise "Replace me with 404"
    end
  end

  def navtree(current \\ nil) do
    [
      {"<code>.</code> <small>(Blog index)</small>", "#{@root}", "dr-x"},
      {"<code>..</code> <small>(Site index)</small>", "/", "dr-x"}
    ] ++ page_listing(current)
  end

  @doc """
  Satisfies the directory listing demanded by the `nav` layout
  """
  def page_listing(current \\ nil) do
    get_articles()
    |> Stream.map(fn {url, meta} ->
      {meta.title, url,
       if Map.get(meta.props, "published", true) do
         Timex.format!(meta.date, "{ISOdate}")
       else
         "DRAFT PAGE"
       end}
    end)
    |> Stream.map(fn {name, url, date} ->
      name =
        if url == current do
          "👉 " <> name <> " 👈"
        else
          name
        end

      {name, url, date}
    end)
    |> Enum.to_list()
  end

  @doc """
  Produces a list of `{url, Meta}` pairs
  """
  def get_articles() do
    src_paths()
    |> Stream.reject(fn p -> ["priv", "pages", p] |> Path.join() |> Home.symlink?() end)
    |> Home.PageCache.cached_many()
    |> Stream.filter(fn {res, _} -> res == :ok end)
    |> Stream.map(fn {:ok, {path, page}} -> {path |> path_to_url(), page.meta} end)
    |> (fn seq ->
          if Mix.env() == :dev,
            do: seq,
            else: seq |> Stream.filter(fn {_, meta} -> meta.published end)
        end).()
    |> Enum.sort_by(fn {_, meta} -> meta.date end, {:desc, DateTime})
  end

  @doc """
  Given a group and article name, finds the path (with datestamp) of the source
  file.
  """
  @spec url_to_path(Path.t(), Path.t()) :: Path.t() | nil
  def url_to_path(group, name) do
    src_paths()
    |> Enum.find(fn path ->
      path |> path_to_url() == [@root, group, name] |> Path.join()
    end)
  end

  @doc """
  Given a filepath, constructs the corresponding site URL.
  """
  @spec path_to_url(Path.t()) :: Path.t()
  def path_to_url(path) do
    ["blog", group, filename] = path |> Path.rootname() |> Path.split()
    [_y, _m, _d, name] = filename |> String.split("-", parts: 4)
    [@root, group, name] |> Path.join()
  end

  def src_paths do
    [@dir, "*", "*.md"]
    |> Path.join()
    |> Path.wildcard()
    |> Stream.filter(&File.regular?/1)
    |> Stream.map(&(&1 |> Path.relative_to("priv/pages")))
  end
end
