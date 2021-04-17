defmodule HomeWeb.Router do
  use HomeWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(HomeWeb.Boycott, nil)
    # plug(:fetch_session)
    # plug(:fetch_flash)
    # plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  # Other scopes may use custom stacks.
  # scope "/api", HomeWeb do
  #   pipe_through :api
  # end

  # Catch XML early
  scope "/", HomeWeb do
    get("/blog.rss", BlogController, :feed)
    get("/blog/feed.rss", BlogController, :feed)
    get("/sitemap.xml", PageController, :sitemap)
    get("/feed.rss", BlogController, :feed)
  end

  scope "/blog", HomeWeb do
    pipe_through(:browser)

    get("/", BlogController, :index)

    get("/*path", BlogController, :page)
  end

  scope "/oeuvre", HomeWeb do
    pipe_through(:browser)

    get("/", OeuvreController, :index)

    get("/*path", OeuvreController, :page)
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through(:browser)
      live_dashboard("/dashboard", metrics: HomeWeb.Telemetry)
    end
  end

  scope "/", HomeWeb do
    pipe_through(:browser)

    get("/", PageController, :home)
    get("/hn", PageController, :refuse)
    get("/favicon.ico", PageController, :favicon_ico)
    get("/klaus", KlausController, :page)
    get("/*path", PageController, :page)
  end
end
