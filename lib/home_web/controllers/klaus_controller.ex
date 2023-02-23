defmodule HomeWeb.KlausController do
  use HomeWeb, :controller

  def page(conn, _params) do
    page = Home.PageCache.cached!("klaus.md")

    conn
    |> put_layout(html: :plain)
    |> render(:page,
      flavor: "klaus",
      classes: ["klaus", "no-index"],
      page: page,
      title: page.meta.title,
      tab_title: page.meta.tab_title
    )
  end
end
