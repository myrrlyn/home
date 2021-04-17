defmodule HomeWeb.BlogView do
  use HomeWeb, :view

  def stale_checks(_template, %{page: page}) do
    [
      etag: PhoenixETag.schema_etag(page),
      last_modified: PhoenixETag.schema_last_modified(page)
    ]
  end

  def stale_checks(_template, %{pages: pages}) do
    adhoc =
      pages
      |> Enum.map(fn {path, meta} ->
        %{
          __struct__: :adhoc,
          id: path,
          updated_at: meta.date
        }
      end)

    [
      etag: PhoenixETag.schema_etag(adhoc),
      last_modified: PhoenixETag.schema_last_modified(adhoc)
    ]
  end
end
