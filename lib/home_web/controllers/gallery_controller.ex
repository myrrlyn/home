defmodule HomeWeb.GalleryController do
  use HomeWeb, :controller

  @root "/gallery"
  @dir ["priv", "pages", @root] |> Path.join()

  def index(conn, _) do
    conn |> PhoenixETag.render_if_stale("")
  end

  def gallery(conn, %{"gallery" => gallery}) do
    conn
    |> render("gallery.html",
      flavor: "app",
      classes: ["general"],
      title: "Icon Gallery",
      banner: Home.Banners.weighted_random(),
      page: nil,
      meta: %Home.Meta{title: "Icon Gallery"},
      navtree: fn -> __MODULE__.navtree() end,
      gravatar: Home.Page.gravatar("self@myrrlyn.dev"),
      scope: @root,
      gallery: gallery
    )
  end

  def banners(conn, _) do
    conn
    |> render("banners.html",
      flavor: "app",
      classes: ["gallery", "banners-gallery"],
      banner: Home.Banners.weighted_random(),
      page: nil,
      meta: %Home.Meta{title: "Banner Images"},
      navtree: &navtree/0,
      gravatar: Home.Page.gravatar("self@myrrlyn.dev"),
      scope: @root,
      directory: "/static/images/banners",
      gallery: Home.Banners.by_albums()
    )
  end

  def iso7010(conn, _) do
    conn
    |> render("gallery.html",
      flavor: "app",
      classes: ["gallery", "iso-7010-gallery"],
      title: "ISO 7010 Icons",
      banner: Home.Banners.weighted_random(),
      page: nil,
      meta: %Home.Meta{title: "ISO 7010 Icons"},
      navtree: &navtree/0,
      gravatar: Home.Page.gravatar("self@myrrlyn.dev"),
      scope: @root,
      directory: "/static/images/iso-7010",
      gallery: %{
        "E (Safe Condition)" =>
          (Enum.to_list(1..13) ++ Enum.to_list(16..19))
          |> Enum.map(fn num ->
            "e#{num |> Integer.to_string() |> String.pad_leading(3, "0")}.svg"
          end),
        "F (Fire Protection)" =>
          Enum.to_list(1..7)
          |> Enum.map(fn num ->
            "f#{num |> Integer.to_string() |> String.pad_leading(3, "0")}.svg"
          end),
        "M (Mandatory)" =>
          Enum.to_list(1..55)
          |> Enum.map(fn num ->
            "m#{num |> Integer.to_string() |> String.pad_leading(3, "0")}.svg"
          end),
        "P (Prohibition)" =>
          (Enum.to_list(1..8) ++ Enum.to_list(10..15) ++ Enum.to_list(17..34))
          |> Enum.map(fn num ->
            "p#{num |> Integer.to_string() |> String.pad_leading(3, "0")}.svg"
          end),
        "W (Warning)" =>
          Enum.to_list(1..67)
          |> Enum.map(fn num ->
            "w#{num |> Integer.to_string() |> String.pad_leading(3, "0")}.svg"
          end)
      }
    )
  end

  def navtree(current \\ nil) do
    [
      {"<code>.</code> <small>(Gallery index)</small>", "#{@root}", "dr-x"},
      {"<code>..</code> <small>(Site index)</small>", "/", "dr-x"}
    ]
  end
end
