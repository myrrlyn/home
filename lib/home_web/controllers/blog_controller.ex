defmodule HomeWeb.BlogController do
  use HomeWeb, :controller

  def index(conn, _params) do
    page = Home.Page.compile("blog/index.md")

    conn
    |> render("index.html",
      banner: "2017-01-28T08-50-37.jpg",
      page: page,
      gravatar: Home.Page.gravatar("self@myrrlyn.dev"),
      navtree: [],
      scope: "blog"
    )
  end

  def dated(conn, params) do
  end

  def sorted(conn, params) do
  end

  def check_draft(conn, page) do
    case page.yaml["published"] do
      nil -> raise "Replace me with 404"
      false -> raise "Replace me with 404"
      true -> conn
    end
  end

  def page_listing do
    []
  end

  def page_listing_new do
    blogroot = ["priv", "pages", "blog"] |> Path.join()

    blogroot
    |> File.ls!()
    |> Enum.filter(fn p -> !String.ends_with?(p, "index.md") end)
    |> Enum.filter(fn p -> Path.extname(p) == ".md" end)
    |> Enum.map(fn a ->
      ["blog", a] |> Path.join()
    end)
    |> Enum.filter(fn p -> !(["priv", "pages", p] |> Path.join() |> File.dir?()) end)
    |> Enum.map(fn p ->
      IO.puts(p)
      p
    end)
    |> Enum.map(&Home.Page.get_yaml/1)
    |> Enum.filter(fn yml -> !List.keyfind(yml, "published", 0, false) end)
  end
end
