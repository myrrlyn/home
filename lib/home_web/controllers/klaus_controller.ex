defmodule HomeWeb.KlausController do
  use HomeWeb, :controller

  def page(conn, _params) do
    page = Home.Page.compile("klaus.md")

    conn
    |> render("page.html",
      layout: {HomeWeb.LayoutView, "plain.html"},
      flavor: "klaus",
      page: page,
      title: page.meta.title
    )
  end
end
