defmodule Home.Meta do
  @moduledoc """
  Parses a YAML frontmatter string into document metadata.
  """
  require Logger

  defmodule BadContent do
    defexception [:message, contents: ""]
  end

  defstruct title: nil,
            subtitle: nil,
            date: nil,
            summary: nil,
            show_toc: true,
            published: true,
            tags: [],
            meta: [],
            props: %{}

  @typedoc """
  Document metadata.

  Metadata must contain a document title. The other fields are all optional.
  """
  @type t :: %__MODULE__{
          title: String.t(),
          subtitle: String.t() | nil,
          date: DateTime.t() | nil,
          summary: String.t() | nil,
          show_toc: bool,
          published: bool,
          tags: [String.t()],
          meta: [{String.t(), String.t()}],
          props: %{String.t() => any}
        }

  @doc """
  Parses a string as YAML, then structures it into a metadata collection.
  """
  def from_string(yaml) do
    try do
      {:ok, yaml |> from_string!}
    rescue
      exn -> {:error, exn}
    end
  end

  @doc """
  Parses a string as YAML, then structures it into a metadata collection. Raises
  on parse or structural error.
  """
  def from_string!(yaml) do
    yaml =
      case yaml |> YamlElixir.read_from_string() do
        {:ok, yml} ->
          yml

        {:error, _} ->
          Logger.error("Received invalid YAML", yaml: yaml)
          raise BadContent, message: "Could not parse YAML", contents: yaml
      end

    {date, yml} = yaml |> multiparse_date!()
    {title, yml} = yml |> Map.pop("title")

    if title == nil do
      Logger.error("YAML frontmatter must have a `title` key", yaml: yaml)
      raise BadContent, message: "YAML frontmatter must have a `title` key", contents: yaml
    end

    {subtitle, yml} = yml |> Map.pop("subtitle")

    {summary, yml} =
      case yml |> Map.pop("summary") do
        {nil, yml} ->
          Logger.warning("YAML frontmatter should include a `summary` key", yaml: yaml)
          {"", yml}

        found ->
          found
      end

    {show_toc, yml} = yml |> Map.pop("toc", true)
    {published, yml} = yml |> Map.pop("published", true)
    {tags, yml} = yml |> Map.pop("tags", [])
    {meta, yml} = yml |> Map.pop("meta", [])
    meta = meta |> Enum.concat()

    %__MODULE__{
      title: title,
      subtitle: subtitle,
      date: date,
      summary: summary,
      published: published,
      show_toc: show_toc,
      tags: tags,
      meta: meta,
      props: yml
    }
  end

  def summary(this, default \\ "") do
    case this.summary do
      "" -> default
      text -> text
    end
  end

  def tags(this, default \\ []) do
    case this.tags do
      [] -> default
      tags -> tags
    end
  end

  @doc """
  Parses the contents of a YAML frontmatter `date:` key.

  Currently this attempts to parse using the Timex formats `RFC3339z`,
  `RFC3339`, and `{ISOdate}`, in that order. If none succed, this raises a
  `BadContent` exception.
  """
  def multiparse_date!(yaml) do
    {datestr, yml} =
      case yaml |> Map.pop("date") do
        {nil, yml} ->
          throw({nil, yml})

        found ->
          found
      end

    # Insert successive parsers here. Each throws on success and allows
    # continuing on error. If control flow passes the last parser, raise an
    # error.
    case datestr |> Timex.parse("{RFC3339z}") do
      {:ok, date} ->
        throw({date, yml})

      {:error, _} ->
        Logger.debug("Datestring #{datestr} is not RFC3339z")
    end

    case datestr |> String.replace(" ", "") |> Timex.parse("{RFC3339}") do
      {:ok, date} ->
        throw({date, yml})

      {:error, _} ->
        Logger.debug("Datestring #{datestr} is not RFC3339")
    end

    case datestr |> Timex.parse("{ISOdate}") do
      {:ok, date} ->
        throw({date |> DateTime.from_naive!("Etc/UTC"), yml})

      {:error, _} ->
        Logger.debug("Datestring #{datestr} is not an ISO-8601 date")
    end

    # If none of the above parsers throw a success, then raise an error.
    Logger.error(
      "YAML frontmatter must have a `date` key whose value is parsable as a date",
      datestr: datestr,
      yaml: yaml
    )

    raise BadContent,
      message: "YAML `date` value must be a well-formed RFC3339 date or datetime string",
      contents: datestr
  catch
    parsed -> parsed
  end
end
