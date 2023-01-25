defmodule HomeWeb.PageController do
  use HomeWeb, :controller

  @doc """
  Renders the main landing page.
  """
  # This might be able to be folded into `page`
  def home(conn, params) do
    conn
    |> build(params, "/", Home.PageCache.cached!("index.md"))
  end

  # Trap `/resume` and forward it to the real URL
  def page(conn, %{"path" => ["resume"]}) do
    conn
    |> put_resp_header("location", "/résumé")
    |> put_resp_content_type("text/plain")
    |> resp(301, "I am pretentious and spell it with the accents")
  end

  # Trap `/résumé` and load it from the ASCII filesystem entry.
  #
  # It is not worth fighting with the various systems which do not tolerate
  # supra-ASCII filenames (my deployment system, Git, etc).
  def page(conn, %{"path" => ["résumé"]} = params) do
    page = Home.PageCache.cached!("resume.md")
    conn |> build(params, "/résumé", page)
  end

  def page(conn, %{"path" => path} = params) do
    path = path |> Path.join()

    case Home.PageCache.cached("#{path}.md") do
      {:ok, page} ->
        conn |> build(params, "/#{path}", page)

      {:error, _} ->
        conn
        |> error(404, params)
    end
  end

  def refuse(conn, _ \\ nil) do
    HomeWeb.Boycott.refuse(conn, nil)
  end

  def sitemap(conn, _) do
    out = Phoenix.View.render(HomeWeb.PageView, "sitemap.xml", [])
    conn |> put_resp_content_type("text/xml") |> resp(200, out)
  end

  defp build(conn, _params, path, page) do
    conn
    |> PhoenixETag.render_if_stale("page.html",
      flavor: "app",
      classes: ["general"],
      title: page.meta.title,
      banner: Home.Banners.weighted_random(),
      page: page,
      meta: page.meta,
      navtree: fn -> __MODULE__.navtree(path) end,
      gravatar: Home.Page.gravatar("self@myrrlyn.dev"),
      scope: ""
    )
  end

  def error(conn, status, _params) do
    conn
    |> put_status(status)
    |> put_view(HomeWeb.ErrorView)
    |> render(
      "404.html",
      flavor: "app",
      classes: ["general"],
      title: "Not Found",
      banner: Home.Banners.weighted_random(),
      page: nil,
      meta: %Home.Meta{title: "Not Found"},
      navtree: &navtree/0,
      gravatar: Home.Page.gravatar("self@myrrlyn.dev"),
      scope: ""
    )
  end

  def navtree(current \\ nil) do
    HomeWeb.Nav.make_listing(page_listing(), current)
  end

  def page_listing() do
    [
      {"Home", "/", "-r--"},
      {"About", "/about", "-r--"},
      {"Blog", "/blog", "dr-x"},
      {"Crates", "/crates", "dr-x"},
      {"Hermaeus", "/hermaeus", "-r--"},
      {"Oeuvre", "/oeuvre", "dr-x"},
      {"Portfolio", "/portfolio", "-r--"},
      {"Résumé", "/résumé", "-r--"},
      {"WebRing", "/webring", "-r--"},
      {"Workbench", "/uses", "-r--"}
    ]
  end
end
