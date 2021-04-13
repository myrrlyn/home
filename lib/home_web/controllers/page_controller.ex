defmodule HomeWeb.PageController do
  use HomeWeb, :controller

  def home(conn, params) do
    conn
    |> build(params, "/", Home.PageCache.cached!("index.md"))
  end

  def page(conn, %{"path" => path} = params) do
    path = path |> Path.join()

    case Home.PageCache.cached("#{path}.md") do
      {:ok, page} ->
        conn |> build(params, "/#{path}", page)

      {:error, _} ->
        conn
        |> resp(
          404,
          "This resource is no longer available. If you are following a formerly-working link, please contact me directly."
        )
    end
  end

  def refuse(conn, _ \\ nil) do
    HomeWeb.Boycott.refuse(conn, nil)
  end

  def sitemap(conn, _) do
    {:safe, out} = Phoenix.View.render(HomeWeb.PageView, "sitemap.xml", [])
    conn |> put_resp_content_type("text/xml") |> resp(200, out |> List.flatten() |> Enum.join())
  end

  defp build(conn, _params, path, page) do
    conn
    |> PhoenixETag.render_if_stale("page.html",
      flavor: "app",
      classes: ["general"],
      title: page.meta.title,
      banner: "banners/2017-01-28T08-50-37.jpg",
      page: page,
      meta: page.meta,
      navtree: fn -> __MODULE__.navtree(path) end,
      gravatar: Home.Page.gravatar("self@myrrlyn.dev"),
      scope: ""
    )
  end

  @doc "Trap requestes for /favicon.ico and forward to the real location"
  def favicon_ico(conn, _) do
    conn |> resp(307, "") |> put_resp_header("location", "/static/images/favicon.ico")
  end

  def navtree(_) do
    page_listing()
  end

  def page_listing do
    [
      {"Home", "/", "-r--"},
      {"About", "/about", "-r--"},
      {"Blog", "/blog", "dr-x"},
      {"Crates", "/crates", "dr-x"},
      {"Hermaeus", "/hermaeus", "-r--"},
      {"Oeuvre", "/oeuvre", "dr-x"},
      {"Portfolio", "/portfolio", "-r--"},
      {"Résumé", "/résumé", "-r--"},
      {"Workbench", "/uses", "-r--"}
    ]
  end
end
