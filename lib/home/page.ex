defmodule Home.Page do
  require Logger

  defmodule NotFoundException do
    defexception [:message, plug_status: 404]
  end

  defmodule BadContentException do
    defexception [:message, plug_status: 500]
  end

  @type toc :: [__MODULE__.toc_entry()]
  @type toc_entry :: {String.t(), String.t(), __MODULE__.toc()}

  defstruct id: nil, updated_at: DateTime.utc_now(), meta: nil, toc: [], content: nil

  @type t :: %__MODULE__{
          # Used for caching
          id: Path.t(),
          updated_at: DateTime.t(),
          # YAML metadata
          meta: Home.Meta.t(),
          # ToC parsed from Markdown
          toc: __MODULE__.toc(),
          # Markdown -> HTML
          content: String.t()
        }

  @doc """
  Compiles a Markdown file into a `Page` object.

  This loads a Markdown file from a path within `priv/pages`, parses it as a
  structured article (YAML frontmatter, Markdown main content), and returns an
  object suitable for rendering.
  """
  @spec compile(Path.t(), Range.t()) :: {:ok, __MODULE__.t()} | {:error, any}
  def compile(path, toc_filter \\ 2..3) do
    p = ["priv", "pages", path] |> Path.join()
    # TODO(myrrlyn): Ensure PageController catches file-not-found Exceptions
    case p |> load do
      {:ok, contents, mtime} ->
        {:ok, build(p, contents, mtime, toc_filter)}

      {:error, :enoent} ->
        {:error, %NotFoundException{message: "File #{p} does not exist"}}
    end
  end

  def compile!(path, toc_filter \\ 2..3) do
    case compile(path, toc_filter) do
      {:ok, page} -> page
      {:error, err} -> raise err
    end
  end

  @doc """
  Gets the metadata for a document.
  """
  def metadata(path) do
    p = ["priv", "pages", path] |> Path.join()

    case p |> load do
      {:ok, text, _} ->
        {yml, _} =
          try do
            text |> split
          rescue
            _ -> raise __MODULE__.BadContentException, message: "Invalid YAML/MD source file"
          end

        yml |> Home.Meta.from_string()

      {:error, :enoent} ->
        {:error, %NotFoundException{message: "File #{p} does not exist"}}
    end
  end

  def metadata!(path) do
    case path |> metadata do
      {:ok, meta} -> meta
      {:error, err} -> raise err
    end
  end

  def build(path, text, mtime, toc_filter) do
    path_date =
      try do
        [y, m, d] =
          case path |> Path.basename() |> String.split("-", parts: 4) do
            [y, m, d, _rest] -> [y, m, d]
            _ -> throw(nil)
          end

        [y, m, d] =
          [y, m, d]
          |> Enum.map(fn part ->
            case part |> Integer.parse() do
              {num, ""} -> num
              _ -> throw(nil)
            end
          end)

        date =
          case Date.new(y, m, d) do
            {:ok, date} -> date
            _ -> throw(nil)
          end

        case DateTime.new(date, ~T[00:00:00], "Etc/UTC") do
          {:ok, date} -> date
          _ -> throw(nil)
        end
      catch
        nil -> nil
      end

    {yaml, md} =
      try do
        text
        |> split
      rescue
        _ ->
          raise __MODULE__.BadContentException, message: "Invalid YAML/MD source file in #{path}"
      end

    {:ok, meta} = yaml |> Home.Meta.from_string()
    {:ok, html, toc, _warns} = md |> Elixir.Home.Markdown.render(toc_filter)

    meta =
      case {meta.date, path_date} do
        {nil, nil} ->
          Logger.warn("YAML frontmatter should have a `date` key", yaml: meta)
          meta

        {nil, date} ->
          Logger.debug(
            "Setting `date` from path: #{path} => #{date |> Timex.format!("{ISOdate}")}"
          )

          %Home.Meta{meta | date: date}

        {_, _} ->
          meta
      end

    meta =
      case meta.props |> Map.get("about") do
        nil ->
          meta

        text ->
          html = text |> Earmark.as_html!()
          %Home.Meta{meta | props: %{meta.props | "about" => html}}
      end

    %__MODULE__{
      id: path,
      updated_at: mtime,
      meta: meta,
      toc:
        if meta.show_toc do
          toc
        else
          []
        end,
      content: html
    }
  end

  @doc """
  Loads a file from `priv/pages` into memory.
  """
  @spec load(Path.t()) :: {:ok, String.t(), DateTime.t()} | {:error, File.posix()}
  def load(path) do
    stat = path |> File.stat(time: :posix)
    text = path |> File.read()

    case {text, stat} do
      {{:ok, text}, {:ok, stat}} -> {:ok, text, stat.mtime |> DateTime.from_unix!()}
      {{:error, err}, _} -> {:error, err}
      {_, {:error, err}} -> {:error, err}
    end
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
end
