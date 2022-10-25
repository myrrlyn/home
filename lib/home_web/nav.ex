defmodule HomeWeb.Nav do
  defmodule Entry do
    defstruct name: nil, url: nil, date: nil, attrs: []

    def new(name, url, date \\ nil, attrs \\ []) do
      %__MODULE__{
        name: name,
        url: url,
        date: date,
        attrs: attrs
      }
    end

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
