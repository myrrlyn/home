defmodule HomeWeb.PageController do
  use HomeWeb, :controller

  @doc """
  Renders the main landing page.
  """
  # This might be able to be folded into `page`
  def home(conn, params) do
    conn
    |> assign(:tab_title, "~myrrlyn")
    |> discover(Map.put(params, "path", []))
  end

  def resume(conn, params) do
    if conn.path_info != ["about", "r%C3%A9sum%C3%A9"] do
      conn |> put_status(301) |> redirect(to: "/about/résumé")
    else
      discover(conn, Map.put(params, "path", ["about", "resume"]))
    end
  end

  def page(conn, params) do
    discover(conn, params)
  end

  def discover(conn, %{"path" => path} = params) do
    case Path.join(["/" | path]) |> HomeWeb.url_to_filepath() do
      nil ->
        error(conn, 404, params)

      {filepath, %File.Stat{type: :symlink}} ->
        redir = filepath |> File.read_link!() |> HomeWeb.filepath_to_url()
        conn |> put_status(301) |> redirect(to: "/#{redir}")

      {filepath, %File.Stat{type: :regular}} ->
        load_fs(conn, params, filepath)
    end
  end

  def load_fs(conn, params, filepath) do
    classes =
      if String.contains?(filepath, "/crates/") || String.contains?(filepath, "/ferrilab/") do
        ["crate"]
      else
        []
      end

    case Home.PageCache.cached(filepath) do
      {:ok, page} ->
        build(conn, page, classes)

      {:error, _} ->
        error(conn, 404, params)
    end
  end

  def refuse(conn, _ \\ nil) do
    HomeWeb.Boycott.refuse(conn, nil)
  end

  def sitemap_xml(conn, %{}) do
    conn |> put_resp_content_type("text/xml") |> render(:sitemap)
  end

  def sitemap_txt(conn, %{}) do
    out = all_pages() |> Enum.join("\n")
    conn |> put_resp_content_type("text/plain") |> send_resp(200, out)
  end

  def all_pages() do
    [
      page_listing(),
      HomeWeb.BlogController.page_listing(),
      HomeWeb.OeuvreController.page_listing()
    ]
    |> Stream.concat()
    |> HomeWeb.Nav.make_listing()
    |> Stream.flat_map(fn
      %HomeWeb.Nav.Entry{children: nil, url: url} ->
        [url]

      %HomeWeb.Nav.Entry{children: children, url: url} ->
        Stream.concat([[url], children |> Stream.map(fn %HomeWeb.Nav.Entry{url: url} -> url end)])
    end)
    |> Stream.map(fn url -> Path.join(HomeWeb.Endpoint.url(), url) end)
  end

  def html_test(conn, _),
    do:
      render(conn, :test,
        flavor: "app",
        classes: [],
        tab_title: "HTML Test",
        page: %Home.Page{
          meta: %Home.Meta{title: "HTML Test", tab_title: "HTML Test"}
        },
        scope: "/",
        navtree: fn -> __MODULE__.navtree("/html-test") end,
        gravatar: Home.Page.gravatar("self@myrrlyn.net")
      )

  defp build(conn, page, classes \\ []) do
    conn
    |> render(:page,
      flavor: "app",
      classes: ["general" | classes],
      tab_title:
        conn.assigns[:tab_title] || page.meta.tab_title ||
          ["~myrrlyn" | conn.path_info] |> Path.join(),
      tab_suffix:
        cond do
          suff = page.meta.props["tab_suffix"] -> suff
          conn.assigns[:tab_title] == "~myrrlyn" -> nil
          conn.assigns[:tab_title] || page.meta.tab_title -> " · ~myrrlyn"
          true -> nil
        end,
      banner: Home.Banners.select_or_random(page.meta),
      page: page,
      frontmatter: page.meta,
      navtree: fn -> conn.request_path |> URI.decode() |> __MODULE__.navtree() end,
      gravatar: get_gravatar(conn.request_path),
      scope: ""
    )
  end

  def error(conn, status, _params) do
    conn
    |> put_status(status)
    |> put_view(HomeWeb.ErrorHTML)
    |> render(
      :"404",
      flavor: "app",
      classes: ["general"],
      tab_title: "Not Found",
      tab_suffix: " · ~myrrlyn",
      page: nil,
      frontmatter: nil,
      navtree: &navtree/0,
      gravatar: Home.Page.gravatar("self@myrrlyn.net"),
      scope: ""
    )
  end

  def navtree(current \\ nil) do
    HomeWeb.Nav.make_listing(page_listing(), current)
  end

  # TODO(myrrlyn): Figure out how to load this from the filesystem?
  @spec page_listing() :: [
          {String.t(), Path.t(), String.t()}
          | {String.t(), Path.t(), String.t(), [{String.t(), Path.t(), String.t()}]}
        ]
  def page_listing() do
    [
      {"Home", "/", "-r--"},
      {"About Me", "/about", "-r--",
       [
         {"Portfolio", "portfolio", "-r--"},
         {"Résumé", "résumé", "-r--"},
         {"Résumé (PDF)", "/papers/resume.pdf", "-r--"}
       ]},
      {"Blog", "/blog", "dr-x"},
      {"Crates", "/crates", "dr-x",
       [
         {"<code>tap</code>", "tap", "-r--"},
         {"<code>calm_io</code>", "calm_io", "-r--"},
         {"<code>wyz</code>", "wyz", "-r--"},
         {"Cosmonaught", "cosmonaught", "-r--"},
         {"<code>lilliput</code>", "lilliput", "-r--"}
       ]},
      {"Ferrilab", "/ferrilab", "-r-x",
       [
         {"<code>bitvec</code>", "bitvec", "-r--"},
         {"<code>radium</code>", "radium", "-r--"},
         {"<code>funty</code>", "funty", "-r--"}
       ]},
      {"Hermaeus", "/hermaeus", "-r--"},
      {"Oeuvre", "/oeuvre", "dr-x"},
      {"WebRing", "/webring", "-r--"},
      {"Workbench", "/uses", "-r--"}
    ]
  end

  defp get_gravatar(path) do
    if String.starts_with?(path, "/crates") || String.starts_with?(path, "/ferrilab") do
      "/static/favicons/ferrilab-2048.png"
    else
      Home.Page.gravatar("self@myrrlyn.net")
    end
  end
end
