defmodule HomeWeb.KlausController do
  use HomeWeb, :controller

  def page(conn, _params) do
    page = Home.PageCache.cached!("klaus.md")

    conn
    |> PhoenixETag.render_if_stale("page.html",
      layout: {HomeWeb.KlausView, "plain.html"},
      flavor: "klaus",
      classes: ["klaus", "no-index"],
      page: page,
      meta: page.meta,
      title: page.meta.title,
      tab_title: page.meta.tab_title
    )
  end
end
