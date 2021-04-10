defmodule HomeWeb.KlausController do
  use HomeWeb, :controller

  def page(conn, _params) do
    page = Home.Page.compile!("klaus.md")

    conn
    |> render("page.html",
      layout: {HomeWeb.LayoutView, "plain.html"},
      flavor: "klaus",
      classes: ["klaus no-index"],
      page: page,
      meta: page.meta,
      title: page.meta.title
    )
  end
end
