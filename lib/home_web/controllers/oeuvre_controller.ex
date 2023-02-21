defmodule HomeWeb.OeuvreController do
  use HomeWeb, :controller

  @root "/oeuvre"
  @dir ["priv", "pages", @root] |> Path.join()

  def index(conn, _params) do
    page = Home.PageCache.cached!("oeuvre/index.md")

    conn |> assign(:tagset, by_tags()) |> build("index.html", nil, page)
  end

  # Renders a single article
  def page(conn, %{"path" => [page]} = params) do
    req_url = [@root, page] |> Path.join()
    path = "oeuvre/#{page}.md"

    case Home.PageCache.cached(path) do
      {:ok, page} ->
        build(conn, "page.html", req_url, page)

      {:error, _} ->
        conn |> HomeWeb.PageController.error(404, params)
    end
  end

  # Data used to procgen the Tones image

  @table [
    {"Mara & Dibella", "C", "aedra", 22, [cube_helix: "#c73cab", hcl: "#ff0088"]},
    {"Namira", "C♯♭", "daedra minor", 23, [cube_helix: "#e5409c", hcl: "#ff005d"]},
    {"Malacath", "C♯", "daedra major", 0, [cube_helix: "#fb4985", hcl: "#ff0033"]},
    {"Vaermina", "C♯♯", "daedra minor", 1, [cube_helix: "#ff586c", hcl: "#fa3600"]},
    {"Zenithar", "D", "aedra", 2, [cube_helix: "#ff6b52", hcl: "#e15800"]},
    {"Clavicus Vile", "D♯♭", "daedra minor", 3, [cube_helix: "#ff833d", hcl: "#c47000"]},
    {"Mehrunes Dagon", "D♯", "daedra major", 4, [cube_helix: "#f59d30", hcl: "#a18100"]},
    {"Peryite", "D♯♯", "daedra minor", 5, [cube_helix: "#e0b92e", hcl: "#798d00"]},
    {"Arkay", "E", "aedra", 6, [cube_helix: "#c9d339", hcl: "#449600"]},
    {"Azura", "E♯", "daedra major", 7, [cube_helix: "#b4e950", hcl: "#009d00"]},
    {"Kyne", "F", "aedra", 8, [cube_helix: "#94f356", hcl: "#00a11d"]},
    {"Meridia", "F♯♭", "daedra minor", 9, [cube_helix: "#6cf65b", hcl: "#00a353"]},
    {"Molag Bal", "F♯", "daedra major", 10, [cube_helix: "#49f46c", hcl: "#00a581"]},
    {"Hircine", "F♯♯", "daedra minor", 11, [cube_helix: "#2eed83", hcl: "#00a6af"]},
    {"Stendarr", "G", "aedra", 12, [cube_helix: "#1ee09f", hcl: "#00a6d9"]},
    {"Sanguine", "G♯♭", "daedra minor", 13, [cube_helix: "#19ceb9", hcl: "#00a5fe"]},
    {"Boethiah", "G♯", "daedra major", 14, [cube_helix: "#1db7cf", hcl: "#00a1ff"]},
    {"Nocturnal", "G♯♯", "daedra minor", 15, [cube_helix: "#299edd", hcl: "#009bff"]},
    {"Akatosh", "A", "aedra", 16, [cube_helix: "#3a85e1", hcl: "#0091ff"]},
    {"Hermaeus Mora", "A♯♭", "daedra minor", 17, [cube_helix: "#4d6cda", hcl: "#0081ff"]},
    {"Sheogorath", "A♯", "daedra major", 18, [cube_helix: "#5e57ca", hcl: "#696cff"]},
    {"Jyggalag", "A♯♯", "daedra minor", 19, [cube_helix: "#6a44b3", hcl: "#b74eff"]},
    {"Julianos", "B", "aedra", 20, [cube_helix: "#833eb0", hcl: "#e61edc"]},
    {"Mephala", "B♯", "daedra major", 21, [cube_helix: "#a63cb2", hcl: "#ff00b3"]}
  ]

  # Renders the Tones SVG
  def page(conn, %{"path" => ["images", "tones.svg"]} = params) do
    {key, params} = params |> Map.pop("key", "d-major")
    {color, params} = params |> Map.pop("color", "hsl")

    {animation, params} = params |> Map.pop("animation", "swirl")

    animation = animation |> String.split(",") |> Enum.map(&String.trim/1)

    classes =
      params
      |> Map.get("classes", "")
      |> String.split(",")
      |> Enum.map(&String.trim/1)

    conn
    # Because Phoenix can’t use any other filename, set the MIME type directly.
    |> put_resp_content_type(MIME.type("svg"))
    |> render("tones.html",
      layout: {HomeWeb.LayoutView, "svg.html"},
      classes: [key, color] ++ animation ++ classes,
      table: @table
    )
  end

  # Gets associated resources
  def page(conn, %{"path" => [folder, resource]} = _params) do
    path = ["priv", "pages", "oeuvre", folder, resource] |> Path.join()

    if path |> File.regular?() do
      conn
      |> put_resp_content_type(resource |> MIME.from_path())
      |> Home.Etag.cache_send_file(200, path)
    else
      conn |> send_resp(404, "Resource not found")
    end
  end

  def page(conn, params), do: conn |> HomeWeb.PageController.error(404, params)

  def build(conn, template, url, page) do
    banner = page.meta.props |> Map.get("banner", "") |> Home.Banners.teslore()

    conn
    |> PhoenixETag.render_if_stale(template,
      flavor: "oeuvre",
      classes: ["oeuvre"],
      banner: banner,
      page: page,
      frontmatter: page.meta,
      tab_title:
        case page.meta.title do
          "oeuvre myrrlyn" -> "oeuvre myrrlyn"
          other -> other <> " – oeuvre myrrlyn"
        end,
      page_title: page.meta.title,
      gravatar: "/oeuvre/images/tones.svg?color=cube-helix&key=d-major&classes=no-names,no-notes",
      navtree: fn -> __MODULE__.navtree(url) end,
      scope: @root
    )
  end

  def by_tags() do
    get_fanfic()
    |> Stream.flat_map(fn {p, meta} ->
      meta.tags |> Stream.map(fn t -> {t, {meta.title, p}} end)
    end)
    |> Enum.group_by(fn {tag, _} -> tag end, fn {_, {title, url}} ->
      {title, "#{url |> Path.rootname()}"}
    end)
    |> Enum.sort_by(fn {_, ps} -> ps |> length() end, :desc)
  end

  def navtree(current \\ nil) do
    [
      HomeWeb.Nav.Entry.new("Library desk <small>(Oeuvre index)</small>", @root),
      HomeWeb.Nav.Entry.new("Lobby <small>(Site index)</small>", "/")
    ]
    |> Stream.concat(HomeWeb.Nav.make_listing(get_fanfic(), current, left: "📖", right: "🪶"))
  end

  def page_listing() do
    get_fanfic()
    |> Stream.map(fn {url, meta} ->
      {meta.title, url,
       if meta.published do
         Timex.format!(meta.date, "{ISOdate}")
       else
         "DRAFT WORK"
       end}
    end)
  end

  def get_fanfic() do
    src_paths()
    |> Home.PageCache.cached_many()
    |> Stream.filter(fn {res, _} -> res == :ok end)
    |> Stream.map(fn {:ok, {path, page}} -> {"/#{path |> Path.rootname()}", page.meta} end)
    |> (fn stream ->
          if Application.get_env(:home, :show_drafts),
            do: stream,
            else: stream |> Stream.filter(fn {_, meta} -> meta.published end)
        end).()
    |> Enum.to_list()
    |> Enum.sort_by(fn {_, meta} -> meta.date end, {:desc, DateTime})
  end

  def src_paths do
    [@dir, "*.md"]
    |> Path.join()
    |> Path.wildcard()
    |> Stream.filter(&File.regular?/1)
    |> Stream.reject(&(Path.basename(&1) in ["index.md", "README.md"]))
    |> Stream.map(&(&1 |> Path.relative_to("priv/pages")))
  end
end
