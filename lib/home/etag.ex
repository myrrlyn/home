defmodule Home.Etag do
  @moduledoc """
  Provides a filter on `Plug.Conn` that computes etag/last-modified values for
  the file backing a given request and 304s when possible
  """

  require Logger

  @doc """
  Equivalent to `Plug.Conn.send_file`, except that it also sends back headers of
  etag/last-modified values. If the request is within the computed etag/mtime,
  then this returns 304; if the request is unaware of etag/mtime or if it is out
  of date, then this forwards to `send_file(conn, status, path)`.
  """
  @spec cache_send_file(Plug.Conn.t(), integer | atom, Path.t()) :: Plug.Conn.t()
  def cache_send_file(conn, status, path) do
    # Attempt to stat the file.
    stat =
      case path |> File.stat(time: :posix) do
        {:error, _} ->
          Logger.warning("Could not stat(#{path})")
          throw(conn)

        {:ok, stat} ->
          stat
      end

    # Attempt to convert `stat.mtime` to a strong structure
    mtime =
      case stat.mtime |> DateTime.from_unix() do
        {:error, _} ->
          Logger.warning("Could not convert #{stat.mtime} to DateTime")
          throw(conn)

        {:ok, mtime} ->
          mtime
      end

    # Attempt to read the file contents.
    contents =
      case path |> File.read() do
        {:error, _} ->
          Logger.warning("Failed to read at #{path}")
          throw(conn)

        {:ok, contents} ->
          contents
      end

    # Hash the file contents into an etag value
    etag = Base.encode16(:crypto.hash(:md5, contents), case: :lower)

    # Test whether the request is out of date w.r.t. the computed current state.
    stale = conn |> stale?(etag, mtime)

    # Set the current etag/mtime headers, then respond.
    conn
    |> Plug.Conn.put_resp_header("etag", etag)
    |> Plug.Conn.put_resp_header("last-modified", mtime |> Timex.format!("{RFC1123}"))
    |> resp(status, path, stale)
  rescue
    # Something in the call stack raised! Give up and send the file normally.
    _ -> conn |> Plug.Conn.send_file(status, path)
  catch
    # One of the filesystem accesses failed. Give up and send the file normally.
    conn -> conn |> Plug.Conn.send_file(status, path)
  end

  @doc """
  Tests if the request headers are out of date with respect to local resources.
  """
  @spec stale?(Plug.Conn.t(), String.t(), DateTime.t()) :: bool
  def stale?(conn, etag, mtime) do
    # Extract the request last-seen headers
    modified_since = conn |> Plug.Conn.get_req_header("if-modified-since") |> List.first()
    none_match = conn |> Plug.Conn.get_req_header("if-none-match") |> List.first()

    # Determine if this request is even asking for a resource
    get = conn.method in ["GET", "HEAD"]

    if get && (modified_since || none_match) do
      modified_since?(modified_since, mtime) || none_match?(none_match, etag)
    else
      true
    end
  end

  # Sends a fresh response when `is_stale` is true; otherwise sends a 304.
  @spec resp(Plug.Conn.t(), integer | atom, Path.t(), bool) :: Plug.Conn.t()
  defp resp(conn, status, path, is_stale) do
    if is_stale do
      # Not ideal since this causes a second read from the fs, allowing a TOCTTOU
      # bug. So don't update files while the server is up.
      conn |> Plug.Conn.send_file(status, path)
    else
      conn |> Plug.Conn.send_resp(304, "")
    end
  end

  # Tests if the local resource is newer than the last-modified header.
  defp modified_since?(header, mtime) do
    DateTime.compare(mtime, header |> Timex.parse!("{RFC1123}")) == :gt
  end

  # Tests if the if-none-match header is unaware of the current etag.
  #
  # Returns `true` if the header does **not** contain the etag.
  defp none_match?(header, etag) do
    if header do
      matches = Plug.Conn.Utils.list(header)
      !(etag in matches || "*" in matches)
    else
      false
    end
  end
end
