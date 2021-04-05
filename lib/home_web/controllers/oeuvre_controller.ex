defmodule HomeWeb.OeuvreController do
  use HomeWeb, :controller

  @root "/oeuvre"
  @dir ["priv", "pages", @root] |> Path.join()

  def index(conn, _params) do
    page = Home.Page.compile("oeuvre/index.md")

    conn |> assign(:tagset, by_tags()) |> build("index.html", nil, page)
  end

  def page(conn, %{"path" => [page]} = _params) do
    req_url = [@root, page] |> Path.join()

    case get_fanfic()
         |> Enum.find(fn {file, _} ->
           file |> Path.rootname() == req_url |> String.trim_leading("/")
         end) do
      {f, _} ->
        build(conn, "page.html", req_url, f |> Home.Page.compile())

      nil ->
        conn |> send_resp(404, "Fanfic not found")
    end
  end

  def page(conn, %{"path" => [folder, resource]} = _params) do
    path = ["priv", "pages", "oeuvre", folder, resource] |> Path.join()

    if path |> File.regular?() do
      conn |> send_file(200, path)
    else
      conn |> send_resp(404, "Resource not found")
    end
  end

  def build(conn, template, url, page) do
    banner = page.yaml |> Map.get("banner", "text-oghma")

    conn
    |> render(template,
      flavor: "oeuvre",
      banner: "oeuvre/#{banner}.jpg",
      page: page,
      gravatar: Home.Page.gravatar("myrrlyn@outlook.com"),
      navtree: page_listing(url),
      scope: @root
    )
  end

  def by_tags() do
    get_fanfic()
    |> Stream.flat_map(fn {p, yml} ->
      yml |> Map.get("tags", ["untagged"]) |> Stream.map(fn t -> {t, {yml["title"], p}} end)
    end)
    |> Enum.group_by(fn {tag, _} -> tag end, fn {_, {title, url}} -> {title, "/#{url |> Path.rootname()}"} end)
    |> Enum.sort_by(fn {_, ps} -> ps |> length() end, :desc)
  end

  def page_listing(current \\ nil) do
    [
      {"Library desk <small>(Oeuvre index)</small>", "#{@root}", nil},
      {"Lobby <small>(Site index)</small>", "/", nil}
    ] ++
      (get_fanfic()
       |> Stream.map(fn {path, yml} ->
         {:ok, date} = yml["date"] |> Home.Page.multiparse_date()
         {:ok, date} = date |> Timex.format("{ISOdate}")

         {"<span class=\"title\">" <> yml["title"] <> "</span>", "/#{path |> Path.rootname()}",
          date}
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

  def get_fanfic() do
    @dir
    |> File.ls!()
    |> Stream.filter(fn p -> Path.join(@dir, p) |> File.regular?() end)
    |> Stream.filter(fn p -> Path.extname(p) == ".md" end)
    |> Stream.reject(fn p ->
      p |> Path.basename() |> Path.rootname() |> String.match?(~r/(index|README)/)
    end)
    |> Stream.map(fn p -> ["oeuvre", p] |> Path.join() end)
    |> Stream.map(fn p -> {p, Home.Page.get_yaml(p)} end)
    |> Stream.filter(fn {_, yml} -> yml |> Map.get("published", true) end)
    |> Enum.to_list()
    |> Enum.sort_by(fn {_, yml} -> yml |> Home.Page.get_date() |> elem(0) end, DateTime)
  end
end
