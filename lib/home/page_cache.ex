defmodule Home.PageCache do
  @moduledoc """
  This memoïzes the `Home.Page.compile` function so that pages can be reüsed
  after first compilation. When accessing the cache, the cached entry is
  compared against the filesystem and if the filesystem has a newer mtime, or if
  the compiled page is older than a requested limit, it is rebuilt from source.

  Currently, this is specialized to *only* cache `Home.Page` objects. In the
  future, it may be worth generalizing this to store *any* filesystem data, and
  to allow path lookups to provide a transform function applied between loading
  data from the filesystem and storing it in the cache.
  """

  use Agent

  require Logger

  @typedoc """
  The cache is a map of `Path` to `Home.Page`.

  It is a flat map, rather than a directory tree, in order to accelerate lookup
  and reduce the duration that the Agent must be locked. Duplication of common
  ancestor path segments is an acceptable memory cost compared to the time and
  complexity costs of a multi-leveled tree structure.
  """
  @type t :: %{Path.t() => Home.Page.t()}

  @doc """
  Initializes the cache.

  ## Parameters

  - `init`: You can supply an initial cache value when starting the service.
  """
  @spec start_link(__MODULE__.t()) :: {:ok, pid} | {:error, any}
  def start_link(init \\ %{}) when is_map(init),
    do: Agent.start_link(fn -> init end, name: __MODULE__)

  @doc """
  Looks up the `Home.Page` object compiled from a given `Path`.

  If the `Path` is not currently represented in the cache, then this attempts to
  load its corresponding file from the filesystem before returning.

  ## Parameters

  - `path`: The path to query in the cache. This must be a valid argument to
    `Home.Page.compile/2`, as it is passed directly to that function.
  - `lifetime:` The number of seconds after load that a cache entry remains
    live. Once a cache entry is older than this lifetime, access requests to it
    cause a reload attempt even if the file system does not indicate an mtime
    update.
  - `toc_filter:` A range of headings to pass into `Home.Page.compile/2`.

  ## Returns

  - `{:ok, page}` if the path produced a valid `Page`, or
  - `{:error, err}` if the call to `Home.Page.compile(path, toc_filter)` failed.

  ## Effects

  If `path` is not currently present in the cache, or if it is and the
  `Home.Page` value it keys has become stale, then the source file is loaded
  from the filesystem and compiled.

  If the source file at `path` in the filesystem is not currently valid to be
  built as a `Home.Page`, then either the prior entry in the cache is renewed
  and returned. This function only propagates failure if the source file at
  `path` is invalid in the filesystem and no previous entry exists.
  """
  @spec cached(Path.t(), Keyword.t()) :: {:ok, Home.Page.t()} | {:error, any}
  def cached(path, opts \\ []) do
    opts = Keyword.merge([lifetime: 86400, toc_filter: 2..3], opts)

    case get(path) do
      # The path has never been loaded from the filesystem; attempt to do so.
      nil ->
        Logger.debug("Inserting #{path} for the first time")
        path |> load_from_fs(opts[:toc_filter])

      page ->
        Logger.debug("Found #{path}, last updated at #{page.updated_at}")

        # The page is expired; attempt to reload from the filesystem.
        if page |> expired?(opts[:lifetime]) do
          case path |> load_from_fs(opts[:toc_filter]) do
            {:ok, page} ->
              {:ok, page}

            # If the filesystem fails, renew the prior entry instead.
            {:error, _} ->
              Logger.error("Error rebuilding #{path}")
              Logger.warning("Renewing the expired Page entry")
              {:ok, _renew(path, page)}
          end
        else
          # The page is not expired; return it as-is.
          {:ok, page}
        end
    end
  end

  @doc """
  Forwards to `cached/2`, returning on `:ok` and raising on `:error`.
  """
  @spec cached!(Path.t(), Keyword.t()) :: Home.Page.t()
  def cached!(path, opts \\ []) do
    case cached(path, opts) do
      {:ok, page} -> page
      {:error, err} -> raise err
    end
  end

  @doc """
  Loads pages from the cache in independent parallel jobs.

  `cached/2` only locks the cache while actively querying or updating it, but
  leaves it unlocked while running `Home.Page.compile/2`. As such, the cache can
  be batch-loaded by running many `Home.Page` compilations in parallel, and only
  performing cache insertions in sequence.

  ## Parameters

  This takes a stream of `Path`s as the first argument, and takes the same
  keyword arguments as `cached/2`.

  ## Returns

  This returns a stream of results from `compile/2`, modified so that the
  payload of both the `:ok` and `:error` variants is a tuple of `{path, object}`
  rather than just the `object`. While the stream is in the same order as the
  supplied paths, explicitly adding the path to the output object makes it
  easier to consume the output stream.
  """
  @spec cached_many(Enumerable.t(), Keyword.t()) :: Enumerable.t()
  def cached_many(paths, opts \\ []) do
    paths
    |> Enum.map(fn path -> Task.async(fn -> {path, cached(path, opts)} end) end)
    |> Stream.map(&(&1 |> Task.await(:infinity)))
    |> Stream.map(fn {path, {status, payload}} -> {status, {path, payload}} end)
  end

  @doc """
  Forwards to `cached_many/2`. Each value in the output stream is unwrapped to
  its `{path, page}` pair on `:ok`. The first `:error` result is raised.
  """
  @spec cached_many!(Enumerable.t(), Keyword.t()) :: Enumerable.t()
  def cached_many!(paths, opts \\ []) do
    cached_many(paths, opts)
    |> Stream.map(fn res ->
      case res do
        {:ok, {path, page}} -> {path, page}
        {:error, {_, err}} -> raise err
      end
    end)
  end

  @doc """
  Renews the `Home.Page` object at a given `path`.

  This does not check the filesystem mtime, and can be used to prevent reloading
  even when the source content has changed.

  ## Effects

  If `path` keys a `Home.Page` object in the cache, then the page’s `updated_at`
  counter is set to the current moment.
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
  Evicts a `path` from the cache.
  """
  @spec evict(Path.t()) :: Home.Page.t() | nil
  def evict(path), do: Agent.get_and_update(__MODULE__, &(&1 |> Map.pop(path)))

  @doc """
  Snapshots the cache state. The cache is free to be modified again once this
  snapshot is taken, and the snapshot can be queried without locking the cache
  (or observing later updates to it).
  """
  @spec snapshot() :: __MODULE__.t()
  def snapshot(), do: Agent.get(__MODULE__, & &1)

  @doc """
  Empties the cache, evicting every entry it contains.
  """
  @spec reset() :: :ok
  def reset(), do: Agent.update(__MODULE__, fn _ -> %{} end)

  @doc """
  Tests if a `Home.Page` object has expired according to either its filesystem
  source or the given `lifetime`.

  ## Parameters

  - `page`: A `Home.Page` object being tested for expiration.
  - `lifetime`: The maximum time, in seconds, that the `Home.Page` can be
    considered live.

  ## Returns

  This returns `true` if either of these conditions holds, or `false` if both do
  not:

  - the `page`’s filesystem source has an mtime newer than the `page` object’s
    `updated_at` value.
  - the `page`’s `updated_at` value is more than `lifetime` seconds in the past.
  """
  @spec expired?(Home.Page.t(), integer) :: bool
  def expired?(%Home.Page{} = page, lifetime \\ 86400) do
    file_mtime =
      case mtime_for(page) do
        {:ok, mtime} ->
          mtime

        # Automatically expire if the mtime could not be read (f.ex., deletion)
        #
        # Note: maybe investigate the error and determine whether the specific
        # error returned indicates expiration or preservation?
        {:error, _} ->
          Logger.error("Error reading the `File.stat()` for #{page.id}")
          throw(true)
      end

    cache_mtime = page.updated_at

    # Test if (a) the file is newer than the in-memory object or (b) the
    # in-memory object is older than `lifetime` allows.
    DateTime.compare(file_mtime, cache_mtime) == :gt ||
      DateTime.diff(DateTime.utc_now(), cache_mtime) > lifetime
  catch
    thrown -> thrown
  end

  @doc """
  Attempts to build a `Home.Page` object from a filesystem `path`, then inserts
  it into the cache.

  ## Parameters

  See `Home.Page.compile/2`.

  ## Returns

  See `Home.Page.compile/2`.

  ## Effects

  If page compilation succeeds, then the built page object is inserted into the
  cache at `path`.
  """
  @spec load_from_fs(Path.t(), Range.t()) :: {:ok, Home.Page.t()} | {:error, any}
  def load_from_fs(path, toc_filter \\ 2..3) do
    case Home.Page.compile(path, toc_filter) do
      {:ok, page} ->
        Logger.debug("Caching #{path} from fs")
        {:ok, _renew(path, page)}

      {:error, err} ->
        Logger.error("Error compiling #{path} as a `Home.Page` for `Home.PageCache`")
        {:error, err}
    end
  end

  @doc """
  Attempts to fetch the `Home.Page` object at a given `path` from the cache.

  ## Parameters

  - `path`: A filesystem path to query in the cache.

  ## Returns

  If `path` is present in the cache, this returns the `Home.Page` it keys; if
  not, it returns `nil`.
  """
  @spec get(Path.t()) :: Home.Page.t() | nil
  def get(path), do: Agent.get(__MODULE__, &(&1 |> Map.get(path)))

  @doc """
  Inserts a `Home.Page` object into the cache at `path`.

  Because this accepts an existing page object, it does not perform any
  filesystem access.

  ## Parameters

  - `path`: The cache key.
  - `page`: The cache value.

  ## Returns

  `page`

  ## Effects

  The cache is updated with `path => page`. Any existing entry is overwritten.
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

  # Looks up the filesystem mtime for an in-memory `Home.Page` object.
  #
  # `Home.Page` objects carry their filesystem path with them so that their
  # source can be re-queried.
  @spec mtime_for(Home.Page.t()) :: {:ok, DateTime.t()} | {:error, File.posix()}
  defp mtime_for(%Home.Page{} = page) do
    case page.id |> File.stat(time: :posix) do
      {:ok, stat} -> stat.mtime |> DateTime.from_unix()
      {:error, err} -> {:error, err}
    end
  end

  # Sets a `Home.Page` object’s `updated_at` field to be the current moment.
  @spec _renew(Home.Page.t()) :: Home.Page.t()
  defp _renew(%Home.Page{} = page), do: %Home.Page{page | updated_at: DateTime.utc_now()}

  # Renews `page`, then inserts it into the cache at `path`.
  @spec _renew(Path.t(), Home.Page.t()) :: Home.Page.t()
  defp _renew(path, %Home.Page{} = page), do: put(path, _renew(page))
end
