defmodule HomeWeb.KlausController do
  use HomeWeb, :controller

  def page(conn, _params) do
    page = Home.Page.compile("klaus.md")

    conn
    |> render("page.html",
      layout: {HomeWeb.LayoutView, "plain.html"},
      page: page,
      title: page.title
    )
  end
end
