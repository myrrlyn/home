defmodule HomeWeb.PageController do
  use HomeWeb, :controller

  def home(conn, params) do
    conn
    |> build(params, "/", Home.Page.compile("home.md"))
  end

  def other(conn, params) do
    path = params["page"] |> Path.join()
    page = Home.Page.compile("#{path}.md")
    conn |> build(params, "/#{path}", page)
  end

  defp build(conn, _params, path, page) do
    conn
    |> render("page.html",
      title: page.title,
      page: page,
      navtree: make_nav(path, page.toc),
      gravatar: Home.Page.gravatar("self@myrrlyn.dev")
    )
  end

  @pages [
    {"Home", "/", []},
    {"About", "/about", []},
    {"Crates", "/crates",
     [
       {"<code>bitvec</code>", "/crates/bitvec", []},
       {"<code>tap</code>", "/crates/tap", []},
       {"<code>calm_io</code>", "/crates/calm_io", []},
       {"<code>wyz</code>", "/crates/wyz", []},
       {"<code>lilliput</code>", "/crates/lilliput", []}
     ]},
    {"Portfolio", "/portfolio", []},
    {"Workbench", "/uses", []},
    {"Résumé", "/résumé", []}
  ]

  def make_nav(path, toc) do
    @pages
    |> Enum.map(fn {n, p, s} ->
      {n, p, s |> apply_toc(path, toc)}
    end)
    |> apply_toc(path, toc)
  end

  def apply_toc(seq, path, toc) do
    seq
    |> Enum.map(fn {n, p, s} ->
      {n, p, s,
       if p == path do
         toc |> Home.Page.render_toc()
       else
         ""
       end}
    end)
  end
end
