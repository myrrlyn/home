defmodule HomeWeb.Components do
  use Phoenix.Component
  use HomeWeb, :verified_routes

  embed_templates "components/*"
end
