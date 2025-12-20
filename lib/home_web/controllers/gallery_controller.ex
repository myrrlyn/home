defmodule HomeWeb.GalleryController do
  use HomeWeb, :controller

  @root "/gallery"

  def index(conn, _) do
    conn |> render("")
  end

  def gallery(conn, %{"gallery" => gallery}) do
    conn
    |> render(:gallery,
      flavor: "app",
      classes: ["general"],
      tab_title: "Icon Gallery",
      page: nil,
      navtree: fn -> __MODULE__.navtree() end,
      gravatar: Home.Page.gravatar("self@myrrlyn.net"),
      scope: @root,
      gallery: gallery
    )
  end

  def banners(conn, _) do
    conn
    |> render(:banner_page,
      flavor: "app",
      classes: ["gallery", "banners-gallery"],
      page: nil,
      tab_title: "Banner Images",
      page_title: "Banner Images",
      navtree: &navtree/0,
      gravatar: Home.Page.gravatar("self@myrrlyn.net"),
      scope: @root,
      directory: "/static/images/banners",
      gallery: Home.Banners.main_banners()
    )
  end

  def iso7010(conn, _) do
    conn
    |> render(:gallery,
      flavor: "app",
      classes: ["gallery", "iso-7010-gallery"],
      title: "ISO 7010 Icons",
      page: nil,
      tab_title: "ISO 7010 Icons",
      page_title: "ISO 7010 Icons",
      navtree: &navtree/0,
      gravatar: Home.Page.gravatar("self@myrrlyn.net"),
      scope: @root,
      directory: "/static/images/iso-7010",
      gallery: %{
        "E (Safe Condition)" =>
          (Enum.to_list(1..4) ++ Enum.to_list(7..70) ++ Enum.to_list(72..76))
          |> Enum.map(fn num ->
            "e#{num |> Integer.to_string() |> String.pad_leading(3, "0")}.svg"
          end),
        "F (Fire Protection)" =>
          Enum.to_list(1..19)
          |> Enum.map(fn num ->
            "f#{num |> Integer.to_string() |> String.pad_leading(3, "0")}.svg"
          end),
        "M (Mandatory)" =>
          (Enum.to_list(1..62) ++ Enum.to_list(68..72))
          |> Enum.map(fn num ->
            "m#{num |> Integer.to_string() |> String.pad_leading(3, "0")}.svg"
          end),
        "P (Prohibition)" =>
          (Enum.to_list(1..75) ++ Enum.to_list(80..81))
          |> Enum.map(fn num ->
            "p#{num |> Integer.to_string() |> String.pad_leading(3, "0")}.svg"
          end),
        "W (Warning)" =>
          (Enum.to_list(1..80) ++ Enum.to_list(87..89))
          |> Enum.map(fn num ->
            "w#{num |> Integer.to_string() |> String.pad_leading(3, "0")}.svg"
          end)
      }
    )
  end

  def navtree(_current \\ nil) do
    [
      {"<code>.</code> <small>(Gallery index)</small>", @root, "dr-x"},
      {"<code>..</code> <small>(Site index)</small>", "/", "dr-x"}
    ]
  end
end
