defmodule HomeWeb.KlausView do
  use HomeWeb, :view

  def stale_checks(_template, %{page: page}) do
    [
      etag: PhoenixETag.schema_etag(page),
      last_modified: PhoenixETag.schema_last_modified(page)
    ]
  end
end
