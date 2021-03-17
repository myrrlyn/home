defmodule HomeWeb.PageController do
  use HomeWeb, :controller

  def home(conn, _params) do
    page = Home.Page.compile("home.md")
    conn |> render("page.html", page: page)
  end

  def other(conn, params) do
    path = params["page"]
    page = Home.Page.compile("#{path}.md")
    conn |> render("page.html", page: page)
  end
end
