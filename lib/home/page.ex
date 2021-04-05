defmodule Home.Page do
  defmodule NotFoundException do
    defexception [:message, plug_status: 404]
  end

  defmodule BadContentException do
    defexception [:message, plug_status: 500]
  end

  @type toc_entry :: {String.t(), String.t(), [toc_entry]}

  defstruct title: nil,
            date: nil,
            slug: nil,
            tags: [],
            category: nil,
            summary: nil,
            about: nil,
            yaml: %{},
            toc: [],
            content: nil

  @type t :: %__MODULE__{
          title: String.t(),
          date: DateTime.t() | nil,
          slug: String.t(),
          tags: [String.t()],
          category: String.t() | nil,
          summary: String.t() | nil,
          about: String.t() | nil,
          yaml: %{},
          toc: [toc_entry],
          content: String.t()
        }

  @doc """
  Compiles a Markdown file into a `Page` object.

  This loads a Markdown file from a path within `priv/pages`, parses it as a
  structured article (YAML frontmatter, Markdown main content), and returns an
  object suitable for rendering.
  """
  @spec compile(String.t(), Range.t()) :: __MODULE__.t()
  def compile(path, toc_filter \\ 2..3) do
    # TODO(myrrlyn): Ensure PageController catches file-not-found Exceptions
    text = path |> load

    {yaml, text} =
      try do
        text
        |> split
      rescue
        _ -> raise __MODULE__.BadContentException
      end

    {:ok, yaml} = yaml |> parse_yaml()
    {{:ok, html, _warns}, toc} = text |> Elixir.Home.Markdown.render(toc_filter)

    {title, yaml} = yaml |> get_title!()
    {date, yaml} = yaml |> get_date()
    {summary, yaml} = yaml |> Map.pop("summary", "")

    {about, yaml} =
      case yaml |> Map.pop("about") do
        {nil, yaml} -> {nil, yaml}
        {about, yaml} -> {about |> String.replace("\n", "\n\n") |> Earmark.as_html!(), yaml}
      end

    {tags, yaml} = yaml |> Map.pop("tags", [])
    {category, yaml} = yaml |> Map.pop("category")
    {use_toc, yaml} = yaml |> Map.pop("toc", true)

    %__MODULE__{
      title: title,
      date: date,
      slug: nil,
      tags: tags,
      category: category,
      summary: summary |> Earmark.as_html!(),
      about: about,
      yaml: yaml,
      toc:
        if use_toc do
          toc
        else
          []
        end,
      content: html
    }
  end

  def load(path) do
    ["priv", "pages", path] |> Path.join() |> File.read!()
  end

  def get_yaml(path) do
    path |> load() |> split() |> elem(0) |> parse_yaml |> elem(1)
  end

  def render_toc([]), do: ""

  def render_toc(hs) do
    list =
      hs
      |> Enum.map(fn {show, anchor, children} ->
        """
        <li><a href="#{anchor}">#{show} #{children |> render_toc}</a></li>
        """
        |> String.trim()
      end)
      |> Enum.join("")

    "<ol>#{list}</ol>"
  end

  @doc """
  Gets the Gravatar URL for an email address.
  """
  @spec gravatar(String.t(), number()) :: String.t()
  def gravatar(email, size \\ 192) do
    email |> Gravatar.new() |> Gravatar.secure() |> Gravatar.size(size) |> to_string
  end

  @doc """
  Splits an input file into its YAML frontmatter and Markdown main content.

  This expects a file of the following structure:

  ```text
  ---
  key: value
  ...
  ---

  # Markdown

  Content goes here...
  ```

  and produces a pair of strings. The first string is the text between the two
  sequences of three or more hyphens, and the second is the text after the
  second such sequence.
  """
  @spec split(String.t()) :: {String.t(), String.t()}
  def split(text) do
    [head, tail] = text |> String.split(~r/\r?\n-{3,}(\r?\n)+/, parts: 2)
    {head |> String.replace(~r/-{3,}\r?\n/, ""), tail}
  end

  @doc """
  Parses a frontmatter section (without the delimiters) as YAML.
  """
  @spec parse_yaml(String.t()) ::
          {:ok, %{String.t() => any}} | {:error, YamlElixir.ParsingError.t()}
  def parse_yaml(yaml) do
    yaml |> YamlElixir.read_from_string()
  end

  @spec get_title!(%{}) :: {String.t(), %{String.t() => any}}
  def get_title!(yaml) do
    case yaml |> Map.pop("title") do
      {nil, rest} ->
        raise Home.Page.Exception,
          message: "YAML frontmatter must have a `title`: key",
          yaml: yaml

      {title, rest} ->
        {title, rest}
    end
  end

  @spec get_date(%{}) :: {nil | DateTime.t(), %{String.t() => any}}
  def get_date(yaml) do
    case yaml |> Map.pop("date") do
      {nil, rest} ->
        {nil, rest}

      {d, rest} ->
        case d |> multiparse_date do
          {:error, msg} -> raise Home.Page.Exception, message: msg, yaml: yaml
          {:ok, d} -> {d, rest}
        end
    end
  end

  @spec make_slug(DateTime.t() | nil, String.t()) :: String.t()
  def make_slug(date, name) do
    date =
      case date do
        nil -> []
        d -> d |> Timex.format!("{ISOdate}") |> String.split("-")
      end

    Path.join(date ++ [name])
  end

  @spec multiparse_date(String.t()) :: {:ok, DateTime.t()} | {:error, String.t()}
  def multiparse_date(date) do
    case date |> Timex.parse("{RFC3339z}") do
      {:ok, d} ->
        {:ok, d}

      {:error, _} ->
        # I currently put a space between the seconds and the TZ, which is not
        # to spec but is IMO more readable.
        case date |> String.replace(" ", "") |> Timex.parse("{RFC3339}") do
          {:ok, d} ->
            {:ok, d}

          {:error, _} ->
            case date |> Timex.parse("{ISOdate}") do
              {:ok, d} -> {:ok, d}
              {:error, _} -> {:error, "Could not parse datestamp"}
            end
        end
    end
  end
end
