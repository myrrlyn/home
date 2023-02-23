defmodule HomeWeb.AssetController do
  @moduledoc """
  Miscellaneous routes that the application has to serve but which are not part
  of its primary structure.
  """
  use HomeWeb, :controller

  @doc "Trap requests for /favicon.ico and forward to the real location."
  def favicon_ico(conn, _) do
    conn
    |> Plug.Conn.send_file(200, "priv/static/favicons/favicon.ico")
  end

  @doc "Trap requests for /keybase.txt and forward to the real location."
  def keybase_txt(conn, params) do
    conn
    |> put_resp_content_type("text/plain")
    |> well_known(Map.put(params, "file", ["keybase.txt"]))
  end

  @doc "Fetch .well-known/ files"
  def well_known(conn, %{"file" => file} = params) do
    path = Path.join(["priv", "static", "well-known"] ++ file)

    if File.exists?(path) do
      conn |> Plug.Conn.send_file(200, path)
    else
      conn |> HomeWeb.PageController.error(404, params)
    end
  end

  def banner_by_album(conn, %{"album" => album} = _params) do
    banner = Home.Banners.random_from_album(album)

    conn
    |> Plug.Conn.send_file(
      200,
      Path.join(["priv", banner |> Phoenix.Param.to_param()])
    )
  end

  def banner_by_tag(conn, %{"tag" => _tag} = _params) do
    conn
  end

  def asset(conn, %{"path" => path} = _params) do
    path = Path.join(["priv", "static"] ++ path)

    if File.exists?(path) do
      conn |> Plug.Conn.send_file(200, path)
    else
      conn |> Plug.Conn.send_resp(404, "No such asset")
    end
  end
end
