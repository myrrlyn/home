# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configures the endpoint
config :home, HomeWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: HomeWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Home.PubSub,
  live_view: [signing_salt: "HHhB0BmM"],
  static_url: [path: "/static"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.14.29",
  default: [
    args:
      ~w(js/app.ts js/klaus.ts js/mathjax.js js/oeuvre.ts --bundle --target=es2017 --outdir=../priv/static/js --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Use the Dart SASS driver for CSS compilation.
config :dart_sass,
  version: "1.55.0",
  default: [
    args: ~w(-Inode_modules css:../priv/static/css),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configure Phoenix's template engines
config :phoenix, :template_engines, heex: Phoenix.LiveView.HTMLEngine

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
