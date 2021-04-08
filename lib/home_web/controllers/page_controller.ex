defmodule HomeWeb.PageController do
  use HomeWeb, :controller

  def home(conn, params) do
    conn
    |> build(params, "/", Home.Page.compile("home.md"))
  end

  def page(conn, params) do
    path = params["path"] |> Path.join()

    try do
      page = Home.Page.compile("#{path}.md")
      conn |> build(params, "/#{path}", page)
    rescue
      _ ->
        conn
        |> resp(
          307,
          "This page is not yet implemented on the new site. Use old.myrrlyn.net in the meantime."
        )
        |> put_resp_header("location", ["https://old.myrrlyn.net", path] |> Path.join())
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
    |> render("page.html",
      flavor: "app",
      title: page.title,
      banner: "banners/2017-01-28T08-50-37.jpg",
      page: page,
      navtree: make_nav(path),
      gravatar: Home.Page.gravatar("self@myrrlyn.dev"),
      scope: ""
    )
  end

  @doc "Trap requestes for /favicon.ico and forward to the real location"
  def favicon_ico(conn, _) do
    conn |> resp(307, "") |> put_resp_header("location", "/static/images/favicon.ico")
  end

  @pages [
    {"Home", "/", "-r--"},
    {"About", "/about", "-r--"},
    {"Blog", "/blog", "dr-x"},
    {"Crates", "/crates", "dr-x"},
    {"Oeuvre", "/oeuvre", "dr-x"},
    {"Portfolio", "/portfolio", "-r--"},
    {"Résumé", "/résumé", "-r--"},
    {"Workbench", "/uses", "-r--"}
  ]

  def page_listing do
    @pages
    |> List.flatten()
  end

  def make_nav(_) do
    @pages
  end
end
