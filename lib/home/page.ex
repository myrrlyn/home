defmodule Home.Page do
  require Logger
  use OK.Pipe

  defmodule NotFoundException do
    @type t :: %__MODULE__{message: String.t(), plug_status: pos_integer()}
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

  This loads a Markdown file from a path, parses it as a structured article
  (YAML frontmatter, Markdown main content), and returns an object suitable for
  rendering.
  """
  @spec compile(Path.t(), Range.t()) :: Wyz.Maybe.result(t(), NotFoundException.t() | any())
  def compile(path, toc_filter \\ 2..3) do
    # The fly.io system shows decomposed filenames for some reason.
    decomposed = path |> String.normalize(:nfkd)
    composed = path |> String.normalize(:nfkc)

    path =
      cond do
        File.exists?(path) ->
          path

        File.exists?(composed) ->
          Logger.notice("The path does not exist as given, but does exist when normalized NFKC")
          composed

        File.exists?(decomposed) ->
          Logger.notice("The path does not exist as given, but does exist when normalized NFKD")
          decomposed

        # Give up, it's the loader’s problem now.
        true ->
          Logger.warning("The path does not exist as given, nor does it when normalized")
          path
      end

    # TODO(myrrlyn): Ensure PageController catches file-not-found Exceptions
    case load(path) do
      {:ok, {contents, mtime}} ->
        build(path, contents, mtime, toc_filter)

      {:error, :enoent} ->
        {:error, %NotFoundException{message: "File #{path} does not exist"}}
    end
  end

  @spec compile!(Path.t(), Range.t()) :: t()
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

    {text, _} = load!(p)

    {yml, _} =
      try do
        split(text)
      rescue
        _ -> raise __MODULE__.BadContentException, message: "Invalid YAML/MD source file"
      end

    yml |> Home.Meta.from_string()
  rescue
    err -> {:error, err}
  end

  def metadata!(path) do
    case path |> metadata do
      {:ok, meta} -> meta
      {:error, err} -> raise err
    end
  end

  @spec build(Path.t(), String.t(), any(), Range.t()) :: Wyz.Maybe.result(t(), any())
  def build(path, text, mtime, toc_filter) do
    path_date = date_from_path(path)

    OK.for do
      {yaml, md} <-
        case YamlFrontMatter.parse(text) do
          {:ok, yaml, md} -> {:ok, {yaml, md}}
          other -> other
        end

      meta <- Home.Meta.from_string(yaml)
      {html, toc, warns} <- Wyz.Markdown.render(md, toc_filter)
    after
      meta = make_meta(meta, path_date, path)

      for warn <- warns do
        warn |> inspect() |> Logger.warning()
      end

      %__MODULE__{
        id: path,
        updated_at: mtime,
        meta: meta,
        toc: if(meta.show_toc, do: toc, else: []),
        content: html
      }
    end
  end

  @doc """
  Loads a file into memory.
  """
  @spec load(Path.t()) :: Wyz.Maybe.result({String.t(), DateTime.t()}, File.posix())
  def load(path) do
    stat = path |> File.stat(time: :posix)
    text = path |> File.read()

    case {text, stat} do
      {{:ok, text}, {:ok, stat}} -> Wyz.Maybe.ok({text, DateTime.from_unix!(stat.mtime)})
      {{:error, err}, _} -> {:error, err}
      {_, {:error, err}} -> {:error, err}
    end
  end

  @doc """
  Loads a file, raising if an error is encountered.
  """
  @spec load!(Path.t()) :: {String.t(), DateTime.t()}
  def load!(path) do
    case load(path) do
      {:ok, {text, date}} ->
        {text, date}

      {:error, :enoent} ->
        raise __MODULE__.NotFoundException, message: "File #{path} does not exist"
    end
  end

  @doc """
  Gets the Gravatar URL for an email address.
  """
  @spec gravatar(String.t(), number()) :: String.t()
  def gravatar(email, size \\ 160) do
    email |> Exgravatar.gravatar_url(size: size)
  end

  @doc """
  Splits an input file into its YAML frontmatter and Markdown main content.

  This expects a file of the following structure:

  ```plain
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
  Extracts a date from a filename that is formatted as `YYYY-MM-DD-restofname`.
  """
  @spec date_from_path(Path.t()) :: DateTime.t() | nil
  def date_from_path(path) do
    # Try to read date fragments from the filename
    [y, m, d] =
      case path |> Path.basename() |> String.split("-", parts: 4) do
        [y, m, d, _rest] -> [y, m, d]
        _ -> throw(nil)
      end
      |> Enum.map(fn part ->
        case part |> Integer.parse() do
          {num, ""} -> num
          _ -> throw(nil)
        end
      end)

    # Try to parse the fragments as a date
    date =
      case Date.new(y, m, d) do
        {:ok, date} -> date
        _ -> throw(nil)
      end

    # And then attach a time (midnight, since we don't have more precision)
    case DateTime.new(date, ~T[00:00:00], "Etc/UTC") do
      {:ok, date} -> date
      _ -> throw(nil)
    end
  catch
    nil -> nil
  end

  @doc """
  Finishes some metadata attributes such as the date (which can be supplied by
  the filename) and descriptive text.
  """
  @spec make_meta(Home.Meta.t(), DateTime.t(), Path.t()) :: Home.Meta.t()
  def make_meta(%Home.Meta{} = meta, path_date, path) do
    # Try to set the date
    meta =
      case {meta.date, path_date} do
        {nil, nil} ->
          Logger.warning("YAML frontmatter should have a `date` key: #{path}")
          meta

        {nil, date} ->
          Logger.debug("Setting date from path: #{path} (#{date |> Timex.format!("{ISOdate}")})")
          %Home.Meta{meta | date: date}

        {_, _} ->
          meta
      end

    # If the metadata contains about-text, render it from Markdown
    case meta.props |> Map.get("about") do
      nil ->
        meta

      text ->
        html = text |> Earmark.as_html!()
        %Home.Meta{meta | props: %{meta.props | "about" => html}}
    end
  end
end
