defmodule HomeWeb.Router do
  use HomeWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(HomeWeb.Boycott, nil)
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {HomeWeb.Layouts, :root}
    # plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(HomeWeb.CacheControl)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :xml do
    plug(:accepts, ["xml"])
    plug :put_format, :html
    plug :put_root_layout, {HomeWeb.Layouts, :xml}
    plug :put_layout, {HomeWeb.Layouts, :bare}
  end

  pipeline :svg do
    # Phoenix doesn't actually support anything other than HTML and JSON here.
    plug :put_format, :html
    plug :put_root_layout, {HomeWeb.Layouts, :svg}
    plug :put_layout, {HomeWeb.Layouts, :bare}
  end

  # Other scopes may use custom stacks.
  # scope "/api", HomeWeb do
  #   pipe_through :api
  # end

  # Catch XML early
  scope "/", HomeWeb do
    pipe_through(:xml)

    get("/sitemap.xml", PageController, :sitemap)

    get("/atom.xml", BlogController, :atom)
    get("/blog.atom", BlogController, :atom)
    get("/blog/atom.xml", BlogController, :atom)
    get("/oeuvre.atom", OeuvreController, :atom)
    get("/oeuvre/atom.xml", OeuvreController, :atom)
  end

  scope "/oeuvre", HomeWeb do
    pipe_through(:svg)

    get("/images/tones.svg", OeuvreController, :tones)
  end

  scope "/blog", HomeWeb do
    pipe_through(:browser)

    get("/", BlogController, :index)
    get("/:category", BlogController, :category)
    get("/:category/:article", BlogController, :article)
    get("/:category/:article/:resource", BlogController, :resource)
    get("/*path", BlogController, :page)
  end

  scope "/oeuvre", HomeWeb do
    pipe_through(:browser)

    get("/", OeuvreController, :index)
    get("/*path", OeuvreController, :page)
  end

  scope "/gallery", HomeWeb do
    pipe_through(:browser)

    # get("/", GalleryController, :index)
    get("/banners", GalleryController, :banners)
    get("/iso7010", GalleryController, :iso7010)
    # get("/:gallery", GalleryController, :gallery)
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

  scope "/static", HomeWeb do
    get("/banners/album/:album", AssetController, :banner_by_album)
    get("/banners/tag/:tag", AssetController, :banner_by_tag)
    get("/*path", AssetController, :asset)
  end

  scope "/", HomeWeb do
    get("/favicon.ico", AssetController, :favicon_ico)
    get("/keybase.txt", AssetController, :keybase_txt)
    get("/.well-known/*file", AssetController, :well_known)
  end

  scope "/", HomeWeb do
    pipe_through(:browser)

    get("/", PageController, :home)

    get("/hn", PageController, :refuse)
    get("/klaus", KlausController, :page)

    get("/*path", PageController, :page)
  end
end
