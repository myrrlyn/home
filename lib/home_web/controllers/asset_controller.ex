defmodule HomeWeb.AssetController do
  @moduledoc """
  Miscellaneous routes that the application has to serve but which are not part
  of its primary structure.
  """
  use HomeWeb, :controller

  @doc "Trap requests for /favicon.ico and forward to the real location."
  def favicon_ico(conn, _) do
    conn |> asset(%{"path" => "favicons/favicon.ico"})
  end

  @doc "Trap requests for /keybase.txt and forward to the real location."
  def keybase_txt(conn, params) do
    conn
    |> put_resp_content_type("text/plain")
    |> well_known(Map.put(params, "file", ["keybase.txt"]))
  end

  @doc "Fetch .well-known/ files"
  def well_known(conn, %{"file" => file}) do
    path = Path.join(["priv", "static", "well-known"] ++ file)

    if File.exists?(path) do
      conn |> Plug.Conn.send_file(200, path)
    else
      conn |> Plug.Conn.send_resp(404, "No such asset")
    end
  end

  @doc """
  Loads a document from the "papers" collection rather than the "static" assets.
  """
  def paper(conn, %{"file" => file}) do
    path = Path.join(["priv", "papers", file])

    sendfile(conn, path)
  end

  @doc """
  Loads a single random banner from a specified album.
  """
  def banner_by_album(conn, %{"album" => album} = _params) do
    path =
      album
      |> Home.Banners.random_from_album()
      |> Phoenix.Param.to_param()

    conn |> asset(%{"path" => path})
  end

  @doc """
  Loads a single random banner from a comma-separated list of tags.
  """
  def banner_by_tags(conn, %{"tags" => tags} = _params) do
    path =
      tags
      |> String.split(",")
      |> Home.Banners.random_from_tags()
      |> Phoenix.Param.to_param()

    conn |> asset(%{"path" => path})
  end

  def asset(conn, %{"path" => path} = _params) do
    path = Path.join(["priv" | ["static" | path]])

    sendfile(conn, path)
  end

  def sendfile(conn, %{"path" => path} = _params) do
    if File.exists?(path) do
      conn
      |> Plug.Conn.put_resp_content_type(MIME.from_path(path))
      |> Plug.Conn.send_file(200, path)
    else
      conn |> Plug.Conn.send_resp(404, "No such asset")
    end
  end
end
