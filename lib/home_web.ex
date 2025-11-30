defmodule HomeWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, components, channels, and so on.

  This can be used in your application as:

      use HomeWeb, :controller
      use HomeWeb, :html

  The definitions below will be executed for every controller,
  component, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  def static_paths, do: ~w(assets fonts images)
  def root_statics, do: ~w(favicon.ico robots.txt)

  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: HomeWeb.Layouts]

      import Plug.Conn

      unquote(verified_routes())
    end
  end

  def router do
    quote do
      use Phoenix.Router, helpers: false

      # Import common connection and controller functions to use in pipelines
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {HomeWeb.Layouts, :app}

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      # HTML escaping functionality
      import Phoenix.HTML
      # Core UI components and translation
      import HomeWeb.Components
      import HomeWeb.CoreComponents

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: HomeWeb.Endpoint,
        router: HomeWeb.Router,
        statics:
          (HomeWeb.static_paths() |> Enum.map(&Path.join("/static", &1)) |> Enum.to_list()) ++
            HomeWeb.root_statics()
    end
  end

  @doc """
  Translates a filename into a URL path segment which would fetch it.

  Removes a leading `priv/pages/`, and collapses `<path>/index.md`,
  `<path>/README.md`, and `<path>.md` to all be just `<path>`.
  """
  @spec filepath_to_url(Path.t()) :: Path.t()
  def filepath_to_url(filepath) do
    cond do
      Path.basename(filepath) == "index.md" -> Path.dirname(filepath)
      Path.basename(filepath) == "README.md" -> Path.dirname(filepath)
      true -> Path.rootname(filepath)
    end
    |> String.replace(~r'^priv/pages/', "")
    |> (&"/#{&1}").()
  end

  @doc """
  Translates a URL path segment into a candidate file. Candidate files all exist
  in `priv/pages`, and are one of:

  1. `priv/pages/<path>.md`
  2. `priv/pages/<path>/index.md`
  3. `priv/pages/<path>/README.md`

  The first file in that sequence which exists produces a `{path, %File.Stat{}}`
  pair. If no such files exist, this produces `nil`.
  """
  @spec url_to_filepath(Path.t() | String.t()) :: {Path.t(), File.Stat.t()} | nil
  def url_to_filepath(url) do
    full = Path.join(["priv", "pages", url])

    [full, String.normalize(full, :nfkd), String.normalize(full, :nfkc)]
    |> Stream.flat_map(fn p ->
      ["#{p}.md", Path.join(p, "index.md"), Path.join(p, "README.md")]
    end)
    |> Stream.map(fn p -> {p, File.lstat(p, time: :posix)} end)
    |> Stream.map(fn
      {p, {:ok, stat}} -> {p, stat}
      {_, {:error, _}} -> nil
    end)
    |> Stream.filter(& &1)
    |> Enum.take(1)
    |> List.first()
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
    # And load them into the cache.
    |> Home.PageCache.cached_many()
    |> Stream.run()
  end

  @doc """
  Lists all the pages available on the site.
  """
  def page_listing() do
    Stream.concat([
      HomeWeb.PageController.page_listing(),
      HomeWeb.BlogController.page_listing(),
      HomeWeb.OeuvreController.page_listing()
    ])
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
