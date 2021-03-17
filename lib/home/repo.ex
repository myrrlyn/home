defmodule Home.Repo do
  use Ecto.Repo,
    otp_app: :home,
    adapter: Ecto.Adapters.Postgres
end
