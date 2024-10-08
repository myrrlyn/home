defmodule HomeWeb.PageController do
  use HomeWeb, :controller

  @doc """
  Renders the main landing page.
  """
  # This might be able to be folded into `page`
  def home(conn, params) do
    conn
    |> Plug.Conn.assign(:tab_title, "~myrrlyn")
    |> build(params, "/", Home.PageCache.cached!("index.md"))
  end

  # Trap `/resume` and forward it to the real URL
  def page(conn, %{"path" => ["resume"]}) do
    conn
    |> put_resp_header("location", "/résumé")
    |> put_resp_content_type("text/plain")
    |> resp(301, "I am pretentious and spell it with the accents")
  end

  # Trap `/résumé` and load it from the ASCII filesystem entry.
  #
  # It is not worth fighting with the various systems which do not tolerate
  # supra-ASCII filenames (my deployment system, Git, etc).
  def page(conn, %{"path" => ["résumé"]}) do
    page = Home.PageCache.cached!("resume.md")
    # conn |> build(params, "/résumé", page)
    pdf = "/papers/resume.pdf"

    conn
    |> render(:pdf,
      flavor: "app",
      classes: ["general", "embed"],
      frontmatter: page.meta,
      tab_title: page.meta.tab_title || ["~myrrlyn" | conn.path_info] |> Path.join(),
      banner: Home.Banners.select_or_random(page.meta),
      page: page,
      foreign: pdf,
      navtree: fn -> __MODULE__.navtree("/résumé") end,
      gravatar: get_gravatar("/résumé"),
      scope: ""
    )
  end

  def page(conn, %{"path" => path} = params) do
    path = path |> Path.join()

    classes =
      if path |> IO.inspect() |> String.starts_with?("crates") do
        ["crate"]
      else
        []
      end

    case Home.PageCache.cached("#{path}.md") do
      {:ok, page} ->
        conn |> build(params, "/#{path}", page, classes)

      {:error, _} ->
        conn
        |> error(404, params)
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

  defp build(conn, _params, path, page, classes \\ []) do
    conn
    |> render(:page,
      flavor: "app",
      classes: ["general" | classes],
      frontmatter: page.meta,
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
      navtree: fn -> __MODULE__.navtree(path) end,
      gravatar: get_gravatar(path),
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
      {"About Me", "/about", "-r--"},
      {"Blog", "/blog", "dr-x"},
      {"Crates", "/crates", "dr-x",
       [
         {"<code>bitvec</code>", "bitvec", "-r--"},
         {"<code>radium</code>", "radium", "-r--"},
         {"<code>funty</code>", "funty", "-r--"},
         {"<code>tap</code>", "tap", "-r--"},
         {"<code>calm_io</code>", "calm_io", "-r--"},
         {"<code>wyz</code>", "wyz", "-r--"},
         {"Cosmonaught", "cosmonaught", "-r--"},
         {"<code>lilliput</code>", "lilliput", "-r--"}
       ]},
      {"Ferrilab", "/ferrilab", "-r-x"},
      {"Hermaeus", "/hermaeus", "-r--"},
      {"Oeuvre", "/oeuvre", "dr-x"},
      {"Portfolio", "/portfolio", "-r--"},
      {"Résumé", "/résumé", "-r--",
       [
         {"PDF Version", "/papers/resume.pdf", "-r--"}
       ]},
      {"WebRing", "/webring", "-r--"},
      {"Workbench", "/uses", "-r--"}
    ]
  end

  defp get_gravatar(path) do
    if String.starts_with?(path, "/crates") do
      "/static/favicons/ferrilab-2048.png"
    else
      Home.Page.gravatar("self@myrrlyn.net")
    end
  end
end
