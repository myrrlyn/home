defmodule HomeWeb.BlogController do
  use HomeWeb, :controller

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

  # Map categorized pages correctly.
  def page(conn, %{"path" => [group, page]} = params) do
    req_url = [@root, group, page] |> Path.join()
    path = url_to_path(group, page)

    conn |> build(params, "page.html", req_url, path)
  end

  # Map nested resources correctly.
  def page(conn, %{"path" => [group, page, resource]} = _params) do
    path = [@dir, group, page, resource] |> Path.join()

    if path |> File.regular?() do
      conn |> Home.Etag.cache_send_file(200, path)
    else
      conn |> send_resp(404, "Resource not found")
    end
  end

  def build(conn, _params, template, req_url, src_path) do
    case src_path |> Home.PageCache.get_page() do
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
        conn |> send_resp(404, "Article not found")
    end
  end

  def grouped_by_category() do
    get_articles()
    |> Enum.group_by(fn {url, _} ->
      ["/", "blog", group, _] = url |> Path.split()
      group |> String.split("-") |> Stream.map(&String.capitalize/1) |> Enum.join(" ")
    end)
    |> Enum.map(fn {name, list} ->
      name =
        case name do
          "Misc" -> "Other"
          n -> n
        end

      {name, list}
    end)
    |> Enum.sort_by(fn {_, list} -> list |> length end, :desc)
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
      {meta.title, url, meta.date |> Timex.format!("{ISOdate}")}
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
    |> Stream.map(fn p -> {p |> path_to_url(), Home.PageCache.get_page!(p).meta} end)
    |> (fn stream ->
          if Mix.env() == :dev,
            do: stream,
            else: stream |> Stream.filter(fn {_, meta} -> meta.published end)
        end).()
    |> Enum.sort_by(fn {_, meta} -> meta.date end, {:desc, DateTime})
  end

  @doc """
  Given a group and article name, finds the path (with datestamp) of the source
  file.
  """
  @spec url_to_path(Path.t(), Path.t()) :: Path.t()
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
