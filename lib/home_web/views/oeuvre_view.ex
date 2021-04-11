defmodule HomeWeb.OeuvreView do
  use HomeWeb, :view

  def stale_checks("tones.html", _) do
    path = ["lib", "home_web", "templates", "oeuvre", "tones.html.eex"] |> Path.join()
    stat = path |> File.stat!(time: :posix)
    text = path |> File.read!()

    record = %{
      __struct__: nil,
      id: text,
      updated_at: stat.mtime |> DateTime.from_unix!()
    }

    [
      etag: PhoenixETag.schema_etag(record),
      last_modified: PhoenixETag.schema_last_modified(record)
    ]
  end

  def stale_checks(_template, %{page: page}) do
    [
      etag: PhoenixETag.schema_etag(page),
      last_modified: PhoenixETag.schema_last_modified(page)
    ]
  end
end
