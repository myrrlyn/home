defmodule HomeWeb.PageController do
  use HomeWeb, :controller

  def home(conn, _params) do
    page = Home.Page.compile("home.md")

    conn
    |> render("page.html",
      title: page.title || "myrrlyn.net",
      page: page,
      top_level: top_level_pages(),
      gravatar: Home.Page.gravatar("self@myrrlyn.dev")
    )
  end

  def other(conn, params) do
    path = params["page"] |> Path.join()
    page = Home.Page.compile("#{path}.md")

    conn
    |> render("page.html",
      title: page.title || "myrrlyn.net",
      page: page,
      top_level: top_level_pages(),
      gravatar: Home.Page.gravatar("self@myrrlyn.dev")
    )
  end

  defp top_level_pages do
    [
      {"Home", "/"},
      {"Crates", "/crates"}
    ]
  end
end
