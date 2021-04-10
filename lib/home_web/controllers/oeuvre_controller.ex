defmodule HomeWeb.OeuvreController do
  use HomeWeb, :controller

  @root "/oeuvre"
  @dir ["priv", "pages", @root] |> Path.join()

  def index(conn, _params) do
    page = Home.Page.compile!("oeuvre/index.md")

    conn |> assign(:tagset, by_tags()) |> build("index.html", nil, page)
  end

  # Renders a single article
  def page(conn, %{"path" => [page]} = _params) do
    req_url = [@root, page] |> Path.join()

    case get_fanfic()
         |> Enum.find(fn {file, _} ->
           file |> Path.rootname() == req_url |> String.trim_leading("/")
         end) do
      {f, _} ->
        page = f |> Home.Page.compile!()
        build(conn, "page.html", req_url, page)

      nil ->
        conn |> send_resp(404, "Fanfic not found")
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
    |> put_resp_content_type("image/svg+xml")
    |> render("tones.html",
      layout: {HomeWeb.LayoutView, "svg.html"},
      classes: ([key, color] ++ animation ++ classes) |> Enum.join(" "),
      table: @table
    )
  end

  # Gets associated resources
  def page(conn, %{"path" => [folder, resource]} = _params) do
    path = ["priv", "pages", "oeuvre", folder, resource] |> Path.join()

    if path |> File.regular?() do
      conn |> send_file(200, path)
    else
      conn |> send_resp(404, "Resource not found")
    end
  end

  def build(conn, template, url, page) do
    banner = page.meta.props |> Map.get("banner", "text-oghma")

    conn
    |> render(template,
      flavor: "oeuvre",
      classes: ["oeuvre"],
      banner: "oeuvre/#{banner}.jpg",
      page: page,
      meta: page.meta,
      gravatar: "/oeuvre/images/tones.svg?color=hcl&key=d-major&classes=no-names,no-notes",
      navtree: navtree(url),
      scope: @root
    )
  end

  def by_tags() do
    get_fanfic()
    |> Stream.flat_map(fn {p, meta} ->
      meta.tags |> Stream.map(fn t -> {t, {meta.title, p}} end)
    end)
    |> Enum.group_by(fn {tag, _} -> tag end, fn {_, {title, url}} ->
      {title, "/#{url |> Path.rootname()}"}
    end)
    |> Enum.sort_by(fn {_, ps} -> ps |> length() end, :desc)
  end

  def navtree(current \\ nil) do
    [
      {"Library desk <small>(Oeuvre index)</small>", "#{@root}", nil},
      {"Lobby <small>(Site index)</small>", "/", nil}
    ] ++
      (page_listing(current)
       |> Enum.map(fn {name, url, date} ->
         {"<span class=\"title\">#{name}</span>", url, date}
       end))
  end

  def page_listing(current \\ nil) do
    get_fanfic()
    |> Stream.map(fn {path, meta} ->
      {:ok, date} = meta.date |> Timex.format("{ISOdate}")

      {meta.title, "/#{path |> Path.rootname()}", date}
    end)
    |> Stream.map(fn {name, url, date} ->
      name =
        if url == current do
          "👉 #{name} 👈"
        else
          name
        end

      {name, url, date}
    end)
    |> Enum.to_list()
  end

  def get_fanfic() do
    @dir
    |> File.ls!()
    |> Stream.filter(fn p -> Path.join(@dir, p) |> File.regular?() end)
    |> Stream.filter(fn p -> Path.extname(p) == ".md" end)
    |> Stream.reject(fn p ->
      p |> Path.basename() |> Path.rootname() |> String.match?(~r/(index|README)/)
    end)
    |> Stream.map(fn p -> ["oeuvre", p] |> Path.join() end)
    |> Stream.map(fn p -> {p, Home.Page.metadata!(p)} end)
    |> Stream.filter(fn {_, meta} -> meta.published end)
    |> Enum.to_list()
    |> Enum.sort_by(fn {_, meta} -> meta.date end, {:desc, DateTime})
  end
end
