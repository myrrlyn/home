defmodule HomeWeb.PageController do
  use HomeWeb, :controller

  def home(conn, params) do
    conn
    |> build(params, "/", Home.Page.compile("home.md"))
  end

  def other(conn, params) do
    path = params["page"] |> Path.join()

    try do
      page = Home.Page.compile("#{path}.md")
      conn |> build(params, "/#{path}", page)
    rescue
      _ ->
        conn |> render("404.html")
    end
  end

  def sitemap(conn, _) do
    {:safe, out} = Phoenix.View.render(HomeWeb.PageView, "sitemap.xml", [])
    conn |> put_resp_content_type("text/xml") |> resp(200, out |> List.flatten() |> Enum.join())
  end

  defp build(conn, _params, path, page) do
    conn
    |> render("page.html",
      title: page.title,
      banner: "2017-01-28T08-50-37.jpg",
      page: page,
      navtree: make_nav(path),
      gravatar: Home.Page.gravatar("self@myrrlyn.dev"),
      scope: ""
    )
  end

  @pages [
    {"Home", "/", []},
    {"About", "/about", []},
    {"Blog", "/blog", []},
    {"Crates", "/crates", []},
    {"Oeuvre", "/oeuvre", []},
    {"Portfolio", "/portfolio", []},
    {"Résumé", "/résumé", []},
    {"Workbench", "/uses", []}
  ]

  def page_listing do
    @pages
    |> Enum.map(fn {name, path, children} -> [{name, path, []} | children] end)
    |> List.flatten()
  end

  def make_nav(_) do
    @pages
  end
end
