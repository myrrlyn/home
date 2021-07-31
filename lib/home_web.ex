defmodule HomeWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use HomeWeb, :controller
      use HomeWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: HomeWeb

      import Plug.Conn
      import HomeWeb.Gettext
      alias HomeWeb.Router.Helpers, as: Routes
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/home_web/templates",
        namespace: HomeWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_flash: 1, get_flash: 2, view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import HomeWeb.Gettext
    end
  end

  @doc """
  Fills the page cache with the website content in `priv/pages`.
  """
  def fill_cache do
    # Get all the Markdown files
    ["priv", "pages", "**", "*.md"]
    |> Path.join()
    |> Path.wildcard()
    |> Stream.filter(&File.regular?/1)
    # But not the READMEs
    |> Stream.reject(&(&1 |> Path.basename() == "README.md"))
    |> Stream.map(&(&1 |> Path.relative_to(["priv", "pages"] |> Path.join())))
    # And load them into the cache.
    |> Home.PageCache.cached_many()
  end

  @doc """
  Lists all the pages available on the site.
  """
  @spec page_listing :: [{String.t(), Path.t(), String.t()}]
  def page_listing do
    HomeWeb.PageController.page_listing() ++
      HomeWeb.BlogController.page_listing() ++ HomeWeb.OeuvreController.page_listing()
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import HomeWeb.ErrorHelpers
      import HomeWeb.Gettext
      alias HomeWeb.Router.Helpers, as: Routes
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
