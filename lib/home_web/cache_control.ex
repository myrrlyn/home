defmodule HomeWeb.CacheControl do
  @moduledoc """
  Provides a `cache-control` response header plug. This plug can be used to
  modify `Plug`’s default settings (`max-age=0`) for various routes, enabling
  browsers and CDNs to cache content rather than being forced to always hit the
  origin server.
  """

  import Plug.Conn

  @default [
    max_age: 86400,
    must_revalidate: false,
    no_cache: false,
    no_store: false,
    no_transform: false,
    visibility: :public,
    proxy_revalidate: false,
    s_max_age: 86400
  ]

  def init(opts), do: opts

  @spec call(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def call(conn, opts) do
    opts = Keyword.merge(@default, opts)
    conn |> put_resp_header("cache-control", make_header(opts))
  end

  defp make_header(opts) do
    {max_age, opts} = Keyword.pop!(opts, :max_age)
    {reval, opts} = Keyword.pop!(opts, :must_revalidate)
    {proxy_reval, opts} = Keyword.pop!(opts, :proxy_revalidate)
    {no_cache, opts} = Keyword.pop!(opts, :no_cache)
    {no_store, opts} = Keyword.pop!(opts, :no_store)
    {no_trans, opts} = Keyword.pop!(opts, :no_transform)
    {vis, opts} = Keyword.pop!(opts, :visibility)
    {s_max_age, _opts} = Keyword.pop!(opts, :s_max_age)

    reval = if reval, do: "must-revalidate", else: nil
    proxy_reval = if proxy_reval, do: "proxy-revalidate", else: nil
    no_cache = if no_cache, do: "no-cache", else: nil
    no_store = if no_store, do: "no-store", else: nil
    no_trans = if no_trans, do: "no-transform", else: nil

    vis =
      case vis do
        :public -> "public"
        :private -> "private"
        _ -> nil
      end

    [
      "max-age=#{max_age}",
      "s-maxage=#{s_max_age}",
      reval,
      proxy_reval,
      no_cache,
      no_store,
      no_trans,
      vis
    ]
    |> Enum.reject(&(&1 == nil))
    |> Enum.join(",")
  end
end
