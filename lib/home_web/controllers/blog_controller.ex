defmodule HomeWeb.BlogController do
  use HomeWeb, :controller

  @root "/blog"
  @dir ["priv", "pages", @root] |> Path.join()

  def index(conn, _params) do
    {:ok, page} = Home.Page.compile("blog/index.md")

    conn
    |> render("index.html",
      flavor: "app",
      banner: "banners/2017-01-28T08-50-37.jpg",
      page: page,
      meta: page.meta,
      gravatar: Home.Page.gravatar("self@myrrlyn.dev"),
      navtree: page_listing(),
      scope: @root
    )
  end

  @doc "Render an RSS feed"
  def feed(conn, _params) do
    conn
    |> put_resp_content_type("application/rss+xml")
    |> render("rss.xml", layout: nil, articles: get_articles())
  end

  # Map categorized pages correctly.
  def page(conn, %{"path" => [group, page]} = _params) do
    req_url = [@root, group, page] |> Path.join()

    case url_to_path(group, page) |> Home.Page.compile() do
      {:ok, page} ->
        conn
        |> render("page.html",
          flavor: "app",
          banner: "banners/2017-01-28T08-50-37.jpg",
          page: page,
          meta: page.meta,
          gravatar: Home.Page.gravatar("self@myrrlyn.dev"),
          navtree: page_listing(req_url),
          scope: @root
        )

      {:error, _err} ->
        conn |> send_resp(404, "Article not found")
    end
  end

  # Map nested resources correctly.
  def page(conn, %{"path" => [group, page, resource]} = _params) do
    path = [@dir, group, page, resource] |> Path.join()

    if path |> File.regular?() do
      conn |> send_file(200, path)
    else
      conn |> send_resp(404, "Resource not found")
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
          "misc" -> "Other"
          n -> n
        end

      {name, list}
    end)
  end

  def check_draft(conn, page) do
    case page.meta.published do
      true -> conn
      _ -> raise "Replace me with 404"
    end
  end

  @doc """
  Satisfies the directory listing demanded by the `nav` layout
  """
  def page_listing(current \\ nil) do
    [
      {"<code>.</code> <small>(Blog index)</small>", "#{@root}", "dr-x"},
      {"<code>..</code> <small>(Site index)</small>", "/", "dr-x"}
    ] ++
      (get_articles()
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
       |> Enum.to_list())
  end

  def get_articles() do
    @dir
    |> File.ls!()
    |> Stream.map(fn p -> [@dir, p] |> Path.join() end)
    |> Stream.filter(&File.dir?/1)
    |> Stream.flat_map(fn p ->
      p
      |> File.ls!()
      |> Stream.map(fn f -> [p, f] |> Path.join() end)
    end)
    |> Stream.filter(&File.regular?/1)
    |> Stream.filter(fn p -> Path.extname(p) == ".md" end)
    |> Stream.reject(fn p ->
      p |> Path.basename() |> Path.rootname() |> String.match?(~r/(index|README)/)
    end)
    |> Stream.map(fn p -> p |> Path.relative_to(["priv", "pages"] |> Path.join()) end)
    |> Stream.map(fn p -> {p, Home.Page.metadata!(p)} end)
    |> Stream.map(fn {p, meta} -> {p |> Path.rootname(), meta} end)
    |> Stream.filter(fn {_, meta} -> meta.published end)
    |> Stream.map(fn {path, meta} -> {path_to_url(path), meta} end)
    |> Enum.sort_by(fn {_, meta} -> meta.date end, DateTime)
  end

  @doc """
  Given a group and article name, finds the path (with datestamp) of the source
  file.
  """
  def url_to_path(group, name) do
    [@dir, group]
    |> Path.join()
    |> File.ls!()
    |> Stream.map(fn filename ->
      ["blog", group, filename] |> Path.join()
    end)
    |> Enum.find(fn path ->
      path |> Path.rootname() |> path_to_url == [@root, group, name] |> Path.join()
    end)
  end

  @doc """
  Given a filepath, constructs the corresponding site URL.
  """
  def path_to_url(path) do
    ["blog", group, filename] = path |> Path.split()
    [_y, _m, _d, name] = filename |> String.split("-", parts: 4)
    [@root, group, name] |> Path.join()
  end
end
