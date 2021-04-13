defmodule Home.PageCache do
  @moduledoc """
  This memoïzes the `Home.Page.compile` function so that pages can be reüsed
  after first compilation. When accessing the cache, the cached entry is
  compared against the filesystem and if the filesystem is newer, or if the
  compiled page is older than a requested limit, it is rebuilt from source.
  """

  use Agent

  require Logger

  @typedoc """
  The cache is a map of `Path` to `Home.Page`.
  """
  @type t :: %{Path.t() => Home.Page.t()}

  @doc """
  Initializes the cache.

  ## Parameters

  - `init`: You can supply an initial cache value when starting the service.
  """
  @spec start_link(__MODULE__.t()) :: {:error, any} | {:ok, pid}
  def start_link(init \\ %{}) when is_map(init),
    do: Agent.start_link(fn -> init end, name: __MODULE__)

  @doc """
  Gets the `Home.Page` object at a given `Path`.

  ## Parameters

  - `path`: The path to query in the cache. Must be a valid argument to
    `Home.Page.compile/2`
  - `lifetime:` The number of seconds to retain a cache entry before expiring it
    and retrying the filesystem even if the source file has not changed.
    Defaults to one day.
  - `toc_filter:` A range of headings to pass into `Home.Page.compile/2`.

  ## Returns

  - `{:ok, page}` if the path produced a valid Page, or
  - `{:error, err}` if `Home.Page.compile(path)` failed.

  ## Effects

  If `path` is not currently present in the cache, or if the `Home.Page` to
  which it points has been updated on the filesystem (or more than `lifetime:`
  seconds have elapsed), then the source file is rebuilt.

  If the source file at `path` is not currently valid to be built as a
  `Home.Page`, then the previously built page is renewed and returned. This only
  fails if the source file at `path` is currently invalid, and no previous page
  entry exists.
  """
  @spec cached(Path.t(), Keyword.t()) :: {:ok, Home.Page.t()} | {:error, any}
  def cached(path, opts \\ []) do
    opts = Keyword.merge([lifetime: 86400, toc_filter: 2..3], opts)

    case get(path) do
      nil ->
        Logger.debug("Inserting #{path} for the first time")
        path |> load_from_fs(opts[:toc_filter])

      page ->
        Logger.debug("Found #{path}, last updated at #{page.updated_at}")

        if page |> expired?(opts[:lifetime]) do
          case path |> load_from_fs(opts[:toc_filter]) do
            {:ok, page} ->
              {:ok, page}

            {:error, _} ->
              Logger.error("Error rebuilding #{path}")
              Logger.warning("Renewing the expired Page")
              {:ok, _renew(path, page)}
          end
        else
          # The page is not expired; return it as-is.
          {:ok, page}
        end
    end
  end

  @doc """
  Fetches a compiled page from the cache or filesystem, raising any errors.
  """
  @spec cached!(Path.t(), Keyword.t()) :: Home.Page.t()
  def cached!(path, opts \\ []) do
    case cached(path, opts) do
      {:ok, page} -> page
      {:error, err} -> raise err
    end
  end

  @doc """
  Gets multiple pages from the cache, roughly in parallel.

  `cached/2` only locks the cache when actively querying it, and unlocks the
  cache while running `Home.Page.compile(path, toc_filter)`. As such, the cache
  can be batch-loaded by running `Home.Page` compilations in parallel, then
  sequentially inserting them into the cache.

  ## Parameters

  - `pages`: A sequence of `Path` arguments passed in to `cached/2`.
  - `lifetime:` and `toc_filter:` See `cached/2`

  ## Returns

  A `Stream` of `{:ok, path, Home.Page}` or `{:error, path, err}` for each
  `path` in `paths`.
  """
  @spec cached_many(Enumerable.t(), Keyword.t()) :: Enumerable.t()
  def cached_many(paths, opts \\ []) do
    paths
    |> Enum.map(fn path -> Task.async(fn -> {path, cached(path, opts)} end) end)
    |> Stream.map(&(&1 |> Task.await(:infinity)))
    |> Stream.map(fn {path, {status, payload}} -> {status, {path, payload}} end)
  end

  @doc """
  Maps `cached_many/2` from a list of fallible `{Path, Home.Page}` entries to a
  list of `{Path, Home.Page}` pairs. The first `{:error, {_, err}}` result is
  raised.
  """
  @spec cached_many!(Enumerable.t(), Keyword.t()) :: Enumerable.t()
  def cached_many!(paths, opts \\ []) do
    opts = Keyword.merge([lifetime: 86400, toc_filter: 2..3], opts)

    cached_many(paths, opts)
    |> Stream.map(fn res ->
      case res do
        {:ok, {path, page}} -> {path, page}
        {:error, {_, err}} -> raise err
      end
    end)
  end

  @doc """
  Renews the `updated_at` counter for the `Home.Page` object at a given `path`.
  This does not check the filesystem mtime, and can be used to prevent reloading
  even when the source content has changed.
  """
  @spec renew(Path.t()) :: :ok
  def renew(path) do
    Agent.update(__MODULE__, fn pages ->
      case pages |> Map.get(path) do
        nil -> pages
        page -> %{pages | path => _renew(page)}
      end
    end)
  end

  @doc """
  Evicts a path from the cache.
  """
  @spec evict(Path.t()) :: Home.Page.t() | nil
  def evict(path) do
    Agent.get_and_update(__MODULE__, &(&1 |> Map.pop(path)))
  end

  @doc """
  Obtains a snapshot of the cache state.
  """
  @spec snapshot :: __MODULE__.t()
  def snapshot(), do: Agent.get(__MODULE__, & &1)

  @doc """
  Empties the cache completely.
  """
  @spec reset() :: :ok
  def reset(), do: Agent.update(__MODULE__, fn _ -> %{} end)

  @doc """
  Tests if a cached page has expired by checking (a) the filesystem and (b) its
  resident time in memory.

  ## Parameters

  - `page`: The `Home.Page.t()` object being tested for expiry.
  - `lifetime`: The maximum time a `Home.Page.t()` object can reside.
  """
  @spec expired?(Home.Page.t(), integer) :: bool
  def expired?(page, lifetime \\ 86400) do
    file_mtime =
      case mtime_for(page) do
        {:ok, mtime} ->
          mtime

        # If the mtime could not be read, expire.
        {:error, _} ->
          Logger.error("Error reading the `File.stat()` for #{page.id}")
          throw(true)
      end

    cache_mtime = page.updated_at

    # Expires if the file mtime is newer than the cached mtime,
    # or if the cached mtime is older than the requested recency threshold.
    DateTime.compare(file_mtime, cache_mtime) == :gt ||
      DateTime.diff(DateTime.utc_now(), cache_mtime) > lifetime
  catch
    thrown -> thrown
  end

  @spec load_from_fs(Path.t(), Range.t()) :: {:ok, Home.Page.t()} | {:error, any}
  def load_from_fs(path, toc_filter \\ 2..3) do
    case Home.Page.compile(path, toc_filter) do
      {:ok, page} ->
        Logger.debug("Loaded #{path} from fs into cache")
        {:ok, _renew(path, page)}

      {:error, err} ->
        Logger.error("Error compiling #{path} as a Home.Page for Home.PageCache")
        {:error, err}
    end
  end

  @spec get(Path.t()) :: Home.Page.t() | nil
  def get(path), do: Agent.get(__MODULE__, &(&1 |> Map.get(path)))

  @doc """
  Inserts a `Home.Page` object into the cache at `path`.
  """
  @spec put(Path.t(), Home.Page.t()) :: Home.Page.t()
  def put(path, %Home.Page{} = page) do
    Agent.get_and_update(__MODULE__, fn pages ->
      case pages |> Map.get(path) do
        nil ->
          {page, pages |> Map.put(path, page)}

        other ->
          newer = Enum.max_by([page, other], & &1.updated_at, DateTime)
          {newer, %{pages | path => newer}}
      end
    end)
  end

  # Queries the filesystem for the mtime of a Page’s source path
  @spec mtime_for(Home.Page.t()) :: {:ok, DateTime.t()} | {:error, any}
  defp mtime_for(page) do
    case page.id |> File.stat(time: :posix) do
      {:ok, stat} -> stat.mtime |> DateTime.from_unix()
      {:error, err} -> {:error, err}
    end
  end

  @spec _renew(Home.Page.t()) :: Home.Page.t()
  defp _renew(%Home.Page{} = page), do: %Home.Page{page | updated_at: DateTime.utc_now()}

  @spec _renew(Path.t(), Home.Page.t()) :: Home.Page.t()
  defp _renew(path, %Home.Page{} = page) do
    put(path, _renew(page))
  end
end
