defmodule HomeWeb.BlogController do
  use HomeWeb, :controller

  @root "/blog"

  def index(conn, _params) do
    page = Home.Page.compile("blog/index.md")

    conn
    |> render("index.html",
      banner: "2017-01-28T08-50-37.jpg",
      page: page,
      gravatar: Home.Page.gravatar("self@myrrlyn.dev"),
      navtree:
        [
          {"<code>.</code> <small>(Blog index)</small>", "#{@root}", "dr-x"},
          {"<code>..</code> <small>(Site index)</small>", "/", "dr-x"}
        ] ++ page_listing(),
      scope: "#{@root}"
    )
  end

  def page(conn, %{"path" => [category, page]} = _params) do
    req_url = [@root, category, page] |> Path.join()

    page =
      get_articles()
      |> Enum.map(fn {file, yml} = pair -> {file, yml, make_link(pair)} end)
      |> Enum.find(fn {_, _, url} -> url == req_url end)
      |> elem(0)
      |> Home.Page.compile()

    conn
    |> render("page.html",
      banner: "2017-01-28T08-50-37.jpg",
      page: page,
      gravatar: Home.Page.gravatar("self@myrrlyn.dev"),
      navtree: page_listing() |> Enum.map(fn {name, url, date} ->
        name =
        if url == req_url do
          "👉 " <> name <> " 👈"
        else
          name
        end
        {name, url, date}
      end),
      scope: @root
    )
  end

  def page(conn, %{"path" => [_, folder, resource]} = _params) do
    path = ["priv", "pages", "blog", folder, resource] |> Path.join()
    if path |> File.regular? do
      conn |> send_file(200, path)
    else
      conn |> send_resp(404, "Resource not found")
    end
  end

  def by_year(conn, _params, _year, _rest) do
    conn
  end

  def by_category(conn, _params, _category, _rest) do
    conn
  end

  def grouped_by_category() do
    get_articles()
    |> Enum.group_by(fn {_, yml} -> yml |> Map.get("category", "misc") end, fn {path, yml} = pair ->
      {yml["title"], pair |> make_link(), path}
    end)
    |> Enum.map(fn {name, list} ->
      name =
        case name do
          "misc" -> "Other"
          n -> n
        end

      {name, list}
    end)
  end

  def check_draft(conn, page) do
    case page.yaml["published"] do
      nil -> raise "Replace me with 404"
      false -> raise "Replace me with 404"
      true -> conn
    end
  end

  @doc """
  Satisfies the directory listing demanded by the `nav` layout
  """
  def page_listing do
    get_articles()
    |> Enum.map(fn {_, yml} = pair ->
      {yml["title"], pair |> make_link(), pair |> Home.Blog.get_date_for()}
    end)
  end

  def get_articles do
    ["priv", "pages", "blog"]
    |> Path.join()
    |> File.ls!()
    |> Stream.filter(fn p -> Path.extname(p) == ".md" end)
    |> Stream.reject(fn p ->
      p |> Path.basename() |> Path.rootname() |> String.match?(~r/(index|README)/)
    end)
    |> Stream.map(fn a ->
      ["blog", a] |> Path.join()
    end)
    |> Stream.filter(fn p -> ["priv", "pages", p] |> Path.join() |> File.regular?() end)
    |> Stream.map(fn p -> {p, Home.Page.get_yaml(p)} end)
    |> Stream.reject(fn {_, yml} -> yml |> Map.get("published", false) end)
    |> Enum.to_list()
    |> Enum.sort_by(&Home.Blog.get_date_for/1)
  end

  def make_link({path, yml}) do
    page = Home.Blog.split_date_title(path)["title"]

    group =
      case yml |> Map.get("category") do
        nil -> yml |> Map.get("date") |> String.replace("-", "/")
        c -> c
      end

    [@root, group, page] |> Path.join() |> String.replace(" ", "-") |> String.downcase()
  end
end
