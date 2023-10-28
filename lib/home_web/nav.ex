defmodule HomeWeb.Nav do
  @moduledoc """
  Assists with the creation of navigation lists.
  """

  defmodule Entry do
    @moduledoc """
    A single entry in a navigation list. Contains a display name, a URL, a date
    (or other marking), and a list of HTML element attributes.
    """
    defstruct(name: nil, url: nil, date: nil, attrs: [], children: nil, contents: [])

    @type t :: %__MODULE__{
            name: String.t(),
            url: String.t(),
            date: String.t() | nil,
            attrs: Keyword.t(),
            children: [__MODULE__.t()] | nil,
            contents: Wyz.Markdown.Heading.tree()
          }

    @doc """
    Produces a new Nav.Entry from its components.
    """
    def new(name, url, date \\ nil, attrs \\ [], children \\ nil, contents \\ []) do
      %__MODULE__{
        name: name,
        url: url,
        date: date,
        attrs: attrs,
        children: children,
        contents: contents
      }
    end

    @doc """
    Marks a navigation entry as being the currently-viewed object.

    This accepts `left:` and `right:` options, which are the decorators applied
    to the entry's name to indicate that it is currently being viewed.
    """
    def mark_current(%__MODULE__{} = this, current, opts \\ []) do
      current? = this.url == current

      attrs =
        if current? do
          [{:"aria-current", :page} | this.attrs] ++ opts
        else
          this.attrs
        end

      children =
        if this.children do
          this.children
          |> Enum.map(fn child -> mark_current(child, current, opts) end)
          |> Enum.to_list()
        else
          nil
        end

      toc = if current?, do: this.contents, else: []

      %__MODULE__{this | attrs: attrs, children: children, contents: toc}
    end
  end

  @doc """
  Makes a stream of `Entry` objects from a stream of semi-structured
  information.

  `entries` can be a stream of:

  - `{url, %Home.Meta{}}`
  - `{url, %Home.Meta{}, %Wyz.Markdown.Heading.tree()}`
  - `{name, url, decorator}`

  The `current` and `opts` arguments are forwarded to `Entry.mark_current`.
  """
  def make_listing(entries, current \\ nil, opts \\ []) do
    entries
    |> Stream.map(&process/1)
    |> Stream.map(&__MODULE__.Entry.mark_current(&1, current, opts))
  end

  defp process({url, %Home.Meta{} = meta}), do: process({url, meta, []})

  defp process({url, %Home.Meta{date: date, published: public, title: title}, toc}) do
    name = "<span class=\"title\">#{title}</span>"

    date =
      if public do
        date = Timex.format!(date, "{ISOdate}")
        "<time datetime=\"#{date}\">#{date}</time>"
      else
        "DRAFT WORK"
      end

    %__MODULE__.Entry{name: name, url: url, date: date, contents: toc}
  end

  defp process({name, url, decorator}) do
    %__MODULE__.Entry{name: name, url: url, date: decorator}
  end

  defp process({name, url, decorator, children}) do
    children =
      children
      |> Stream.map(fn {name, child_url, decorator} ->
        {name,
         if String.starts_with?(child_url, "/") do
           child_url
         else
           Path.join(url, child_url)
         end, decorator}
      end)
      |> Stream.map(&process/1)
      |> Enum.to_list()

    %__MODULE__.Entry{name: name, url: url, date: decorator, children: children}
  end
end
