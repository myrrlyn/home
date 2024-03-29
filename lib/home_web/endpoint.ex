defmodule HomeWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :home

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_home_key",
    signing_salt: "DSvDoWpE"
  ]

  socket "/socket", HomeWeb.UserSocket,
    websocket: true,
    longpoll: false

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  # Certain static files are expected at the site root.
  plug Plug.Static,
    at: "/",
    from: :home,
    gzip: true,
    only: ~w(favicon.ico robots.txt)

  # Others are expected in `/.well-known/`.
  plug Plug.Static,
    at: "/.well-known",
    from: {:home, "priv/static/well-known"},
    gzip: true

  # Serve at "/static" the rest of the static files from "priv/static" directory
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/static",
    from: :home,
    gzip: true,
    brotli: true,
    only: ~w(css favicons fonts images js music)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options
  plug HomeWeb.Router
end
