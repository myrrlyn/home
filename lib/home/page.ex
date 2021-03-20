defmodule Home.Page do
  defmodule Home.Page.Exception do
    defexception [:message, :yaml]
  end

  defstruct title: nil,
            date: nil,
            slug: nil,
            tags: [],
            category: nil,
            summary: nil,
            yaml: %{},
            content: nil

  @type t :: %__MODULE__{
          title: String.t(),
          date: DateTime.t() | nil,
          slug: String.t(),
          tags: [String.t()],
          category: String.t() | nil,
          summary: String.t() | nil,
          yaml: %{},
          content: String.t()
        }

  @doc """
  Compiles a Markdown file into a `Page` object.

  This loads a Markdown file from a path within `priv/pages`, parses it as a
  structured article (YAML frontmatter, Markdown main content), and returns an
  object suitable for rendering.
  """
  @spec compile(String.t()) :: __MODULE__.t()
  def compile(file) do
    {yaml, text} = Path.join(["priv", "pages", file]) |> File.read!() |> split
    {:ok, yaml} = yaml |> parse_yaml()
    {:ok, html, _warns} = text |> earmark()

    %__MODULE__{
      title: yaml |> get_title!,
      date: yaml |> get_date,
      slug: nil,
      tags: [],
      category: nil,
      summary: "",
      yaml: yaml |> Map.delete("title") |> Map.delete("date"),
      content: html
    }
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
    [head, tail] = text |> String.split(~r/\n-{3,}\n+/, parts: 2)
    {head |> String.replace(~r/-{3,}\n/, ""), tail}
  end

  @doc """
  Parses a frontmatter section (without the delimiters) as YAML.
  """
  @spec parse_yaml(String.t()) ::
          {:ok, %{String.t() => any}} | {:error, YamlElixir.ParsingError.t()}
  def parse_yaml(yaml) do
    yaml |> YamlElixir.read_from_string()
  end

  @doc """
  Compiles a Markdown content body into HTML.
  """
  @spec earmark(String.t()) ::
          {:error, String.t(), list} | {:ok, String.t(), list}
  def earmark(md) do
    opts = %Earmark.Options{
      gfm: true,
      breaks: false,
      code_class_prefix: "lang- language-",
      smartypants: false,
      postprocessor: &__MODULE__.transform/1
    }

    md |> Earmark.as_html(opts)
  end

  @spec get_title!(%{}) :: String.t()
  def get_title!(yaml) do
    case yaml |> Map.get("title") do
      nil ->
        raise Home.Page.Exception,
          message: "YAML frontmatter must have a `title`: key",
          yaml: yaml

      t ->
        t
    end
  end

  @spec get_date(%{}) :: nil | DateTime.t()
  def(get_date(yaml)) do
    case yaml |> Map.get("date") do
      nil ->
        nil

      d ->
        case d |> multiparse_date do
          {:error, msg} -> raise Home.Page.Exception, message: msg, yaml: yaml
          {:ok, d} -> d
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
        case date |> Timex.parse("{RFC3339}") do
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

  @doc """
  Applies a transform filter to a piece of an Earmark AST.

  This function will be invoked for each HTML node generated by a Markdown
  document. It is invoked on each node as the serializer descends through the
  tree, so
  """
  @spec transform(Earmark.ast()) :: Earmark.ast()
  def transform(ast)

  # Attaches a `codeblock-LANG` class to `<pre>` tags that contain a tagged
  # `<code>` block.
  def transform({"pre", attrs, [{"code", code_attrs, _, _}] = inner, tail}) do
    code_classes = code_attrs |> List.keyfind("class", 0, {"class", ""}) |> elem(1)

    code_lang =
      code_classes
      |> extract_lang

    {classes, rest} =
      case attrs |> List.keytake("class", 0) do
        nil ->
          {[], attrs}

        {{"class", classes}, rest} ->
          {classes |> String.split(), rest}
      end

    classes =
      ["codeblock" | ["codeblock-#{code_lang}" | classes]] |> Enum.uniq() |> Enum.join(" ")

    {"pre", [{"class", classes} | rest], inner, tail}
  end

  def transform(ast) do
    # ast |> inspect |> IO.puts()
    ast
  end

  def extract_lang(classes) do
    classes
    |> String.split()
    |> Enum.find("language-text", fn lang -> lang |> String.starts_with?("language-") end)
    |> String.trim_leading("language-")
  end
end
