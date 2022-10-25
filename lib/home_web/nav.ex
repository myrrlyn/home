defmodule HomeWeb.Nav do
  @moduledoc """
  Assists with the creation of navigation lists.
  """

  defmodule Entry do
    @moduledoc """
    A single entry in a navigation list. Contains a display name, a URL, a date
    (or other marking), and a list of HTML element attributes.
    """
    defstruct name: nil, url: nil, date: nil, attrs: []

    @doc """
    Produces a new Nav.Entry from its components.
    """
    def new(name, url, date \\ nil, attrs \\ []) do
      %__MODULE__{
        name: name,
        url: url,
        date: date,
        attrs: attrs
      }
    end

    @doc """
    Marks a navigation entry as being the currently-viewed object.

    This accepts `left:` and `right:` options, which are the decorators applied
    to the entry's name to indicate that it is currently being viewed.
    """
    def mark_current(%__MODULE__{name: name, attrs: attrs} = this, current, opts) do
      opts = Keyword.merge([left: "👉", right: "👈"], opts)

      {name, attrs} =
        if this.url == current do
          {"#{opts[:left]} #{name} #{opts[:right]}", [{:"aria-current", :page} | attrs]}
        else
          {name, attrs}
        end

      %__MODULE__{this | name: name, attrs: attrs}
    end
  end

  @doc """
  Makes a stream of `Entry` objects from a stream of semi-structured
  information.

  `entries` can be a stream of:

  - `{url, %Home.Meta{}}`
  - `{name, url, decorator}`

  The `current` and `opts` arguments are forwarded to `Entry.mark_current`.
  """
  def make_listing(entries, current \\ nil, opts \\ []) do
    entries
    |> Stream.map(&process/1)
    |> Stream.map(&__MODULE__.Entry.mark_current(&1, current, opts))
  end

  defp process({url, %Home.Meta{date: date, published: public, title: title}}) do
    name = "<span class=\"title\">#{title}</span>"

    date =
      if public do
        date = Timex.format!(date, "{ISOdate}")
        "<time datetime=\"#{date}\">#{date}</time>"
      else
        "DRAFT WORK"
      end

    __MODULE__.Entry.new(name, url, date, [])
  end

  defp process({name, url, decorator}) do
    __MODULE__.Entry.new(name, url, decorator, [])
  end
end
