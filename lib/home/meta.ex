defmodule Home.Meta do
  @moduledoc """
  Parses a YAML frontmatter string into document metadata.
  """
  require Logger

  defmodule BadContent do
    @type t :: %__MODULE__{message: String.t(), contents: %{String.t() => any()}}
    defexception [:message, contents: %{}]
  end

  defstruct title: nil,
            subtitle: nil,
            tab_title: nil,
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
          tab_title: String.t() | nil,
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
  def from_string!(yml) do
    {title, yml} = yml |> Map.pop("title")

    unless title do
      Logger.error("YAML frontmatter must have a `title` key", yaml: yml)
      raise BadContent, message: "YAML frontmatter must have a `title` key", contents: yml
    end

    {date_str, yml} = yml |> Map.pop("date")
    date = multiparse_date!(date_str)

    {subtitle, yml} = yml |> Map.pop("subtitle")
    {tab_title, yml} = yml |> Map.pop("tab_title")
    {summary, yml} = yml |> Map.pop("summary", "")

    if summary == "" do
      Logger.warning("YAML frontmatter should include a `summary` key", yaml: yml)
    end

    {show_toc, yml} = yml |> Map.pop("toc", true)
    {published, yml} = yml |> Map.pop("published", true)
    {tags, yml} = yml |> Map.pop("tags", [])
    {meta, yml} = yml |> Map.pop("meta", [])
    meta = meta |> Enum.concat()

    %__MODULE__{
      title: title,
      subtitle: subtitle,
      tab_title: tab_title,
      date: date,
      summary: summary,
      published: published,
      show_toc: show_toc,
      tags: tags,
      meta: meta,
      props: yml
    }
  end

  @doc "Gets the page’s author, if any."
  def author(this, default \\ "") do
    this.props["author"] || default
  end

  @doc "Gets the page’s summary, if any."
  def summary(this, default \\ "") do
    case this.summary do
      "" -> default
      text -> text
    end
  end

  def updated(this) do
    this.props["updated"] |> multiparse_date!()
  end

  @doc "Gets the page’s tags, if any."
  def tags(this, default \\ []) do
    case this.tags do
      [] -> default
      tags -> tags
    end
  end

  @doc """
  Parses the contents of a date string.

  Currently this attempts to parse using the Timex formats `RFC3339z`,
  `RFC3339`, `ISO:Extended`, and `ISOdate`, in that order. If none succed, this
  raises a `BadContent` exception.
  """
  @spec multiparse_date!(String.t() | nil) :: NaiveDateTime.t() | nil
  def multiparse_date!(_arg)

  def multiparse_date!(nil), do: nil

  def multiparse_date!(date_str) when is_binary(date_str) do
    # Insert successive parsers here. Each bails on success and allows
    # continuing on error. If control flow passes the last parser, raise an
    # error.
    with {:error, _} <- Timex.parse(date_str, "{RFC3339z}"),
         {:error, _} <- Timex.parse(date_str, "{RFC3339}"),
         {:error, _} <- Timex.parse(date_str, "{ISO:Extended}"),
         {:isodate, {:error, _}} <- {:isodate, Timex.parse(date_str, "{ISOdate}")} do
      # If none of the above parsers throw a success, then raise an error.
      Logger.error("the provided string is not parseable as a date", date_str: date_str)

      raise BadContent,
        message:
          "frontmatter date values must be a well-formed RFC-3339 or ISO-8601 date or date-time string",
        contents: date_str
    else
      {:ok, date} -> date
      {:isodate, {:ok, date}} -> DateTime.from_naive!(date, "Etc/UTC")
    end
  end
end
