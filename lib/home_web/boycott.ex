defmodule HomeWeb.Boycott do
  import Plug.Conn

  def init(default), do: default

  def call(conn, opts) do
    case conn.req_headers |> List.keyfind("referer", 0, nil) do
      nil ->
        conn

      {_, src} ->
        if String.match?(src, ~r/news\.ycombinator\.com/) do
          conn |> refuse(opts) |> halt()
        else
          conn
        end
    end
  end

  def refuse(conn, _opts \\ nil) do
    conn |> put_resp_content_type("text/html") |> send_file(403, "priv/pages/hn.html")
  end
end
