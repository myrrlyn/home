defmodule Home.PageCache do
  @moduledoc """
  This serves as a memoÏzation of
  `Path.t() -> {:ok, Home.Page.t()} | {:error, _}` that on read compares the
  in-memory mtime to the on-disk mtime and transparently updates the in-memory
  cache when the filesystem advances past it.
  """
  use Agent
  require Logger

  @type cache :: %{Path.t() => Home.Page.t()}

  def start_link(_opts \\ []), do: Agent.start_link(fn -> %{} end, name: __MODULE__)

  @doc """
  Gets the `Home.Page.t()` object corresponding to a particular `Path.t()`.

  ## Parameters

  - `path`: The path to query in the cache. Must be a valid argument to
    `Home.Page.compile`.
  - `lifetime`: The maximum allowable time, in seconds, that a `Page` entry can
    be kept in the cache before it has to be reloaded from disk. Defaults to one
    day.

  ## Returns

  - `{:ok, page}` if the path produced a valid Page, or
  - `{:error, err}` if `Home.Page.compile(path)` failed.

  ## Effects

  If `path` is not currently present in the cache, or if the `Home.Page` to
  which it points has been updated on the filesystem or more than `lifetime`
  seconds ago, then the source file is rebuilt.

  If the source file at `path` is not valid to be built as a `Home.Page`, then
  this returns the error and removes the cache entry.
  """
  @spec get_page(Path.t(), integer) :: {:ok, Home.Page.t()} | {:error, any}
  def get_page(path, lifetime \\ 86400) do
    Agent.get_and_update(__MODULE__, fn pages ->
      case pages |> Map.get(path) do
        # The path has not yet been stored; load from fs
        nil ->
          Logger.debug("Inserting #{path} for the first time")
          pages |> load_from_fs(path)

        # An entry exists; check it for expiry
        page ->
          Logger.debug("Found #{path}, last updated at #{page.updated_at}")

          if page |> expired?(lifetime) do
            Logger.debug("Stale #{page.id}, reloaded")
            # The page expired; reload it from fs
            case pages |> load_from_fs(path) do
              {{:ok, page}, pages} ->
                {{:ok, page}, pages}

              # If the path fails to rebuild, we still have a successfully built
              # Page. Renew its lifetime and continue serving it.
              {{:error, err}, pages} ->
                Logger.error("Error rebuilding #{path}: #{err}")
                Logger.warning("Renewing the expired Page")
                page = _renew(page)
                {{:ok, page}, %{pages | path => page}}
            end
          else
            # The page is not expired; return it and the unmodified cache.
            {{:ok, page}, pages}
          end
      end
    end)
  end

  @doc """
  Fetches a compiled page from the cache or filesystem, raising any errors.
  """
  @spec get_page!(Path.t()) :: Home.Page.t()
  def get_page!(path) do
    case get_page(path) do
      {:ok, page} -> page
      {:error, err} -> raise err
    end
  end

  @doc """
  Renews the `update_at` counter for the `Home.Page` value at a given `path`.
  This does not check the filesystem mtime, and can be used to prevent reloading
  even when the source content has changed.
  """
  @spec renew(Path.t()) :: :ok
  def renew(path) do
    Agent.get_and_update(__MODULE__, fn pages ->
      {:ok, _renew(pages, path)}
    end)
  end

  @doc """
  Evicts a path from the cache.
  """
  @spec evict(Path.t()) :: Home.Page.t() | nil
  def evict(path) do
    Agent.get_and_update(__MODULE__, fn pages -> pages |> Map.pop(path) end)
  end

  @doc """
  Obtains a snapshot of the cache state.
  """
  @spec snapshot :: __MODULE__.cache()
  def snapshot do
    Agent.get(__MODULE__, fn pages -> pages end)
  end

  @doc """
  Empties the cache completely.
  """
  @spec reset :: :ok
  def reset do
    Agent.update(__MODULE__, fn _ -> %{} end)
  end

  @doc """
  Tests if a cached page has expired by checking (a) the filesystem and (b) its
  resident time in memory.

  ## Parameters

  - `page`: The `Home.Page.t()` object being tested for expiry
  - `lifetime`: The maximum time a `Home.Page.t()` object can reside
  """
  @spec expired?(Home.Page.t(), integer | nil) :: bool
  def expired?(page, lifetime \\ 86400) do
    file_mtime =
      case mtime_for(page) do
        {:ok, mtime} ->
          mtime

        # If the mtime could not be read, expire.
        {:error, err} ->
          Logger.error("Error reading the `File.stat` for #{page.id}: #{err}")
          throw(true)
      end

    cache_mtime = page.updated_at

    # Expires if the file mtime is newer than the cached mtime,
    # or if the cached mtime older than the requested recency threshold.
    DateTime.compare(file_mtime, cache_mtime) == :gt ||
      DateTime.diff(DateTime.utc_now(), cache_mtime) > lifetime
  catch
    thrown ->
      thrown
  end

  @doc """
  Loads a `Home.Page.t()` from the filesystem into the cache.

  ## Parameters

  - `pages`: A map of paths to page/time pairs.
  - `path`: The path of the page to be fetched into cache.

  ## Returns

  - `{{:ok, page}, %{pages | path => page}}` if the path produced a valid `Page`
  - `{{:error, err}, pages}` if the path did not produce a valid `Page`. `pages`
    is not modified.
  """
  @spec load_from_fs(__MODULE__.cache(), Path.t()) ::
          {{:ok, Home.Page.t()} | {:error, any}, __MODULE__.cache()}
  def load_from_fs(pages, path) do
    case Home.Page.compile(path) do
      # Store `{page, now}` in the cache, then return success and the new cache.
      {:ok, page} ->
        Logger.debug("Loaded #{path} from fs into cache")
        # Set the mtime to be now in order to cachebust HTTP ETags. This ensures
        # that updates to site context outside the source file still propagate.
        page = %Home.Page{page | updated_at: DateTime.utc_now()}
        {{:ok, page}, pages |> Map.put(path, page)}

      # Return failure and the original cache.
      {:error, err} ->
        Logger.error("Error compiling #{path} as a Home.Page: #{err}")
        {{:error, err}, pages}
    end
  end

  # Queries the filesystem for the mtime of a Page’s source path
  @spec mtime_for(Home.Page.t()) :: {:ok, DateTime.t()} | {:error, any}
  defp mtime_for(page) do
    case page.id |> File.stat(time: :posix) do
      {:ok, stat} -> stat.mtime |> DateTime.from_unix()
      {:error, err} -> {:error, err}
    end
  end

  # Renew the Page at `path` in `pages`
  @spec _renew(__MODULE__.cache(), Path.t()) :: __MODULE__.cache()
  defp _renew(pages, path)

  defp _renew(pages, path) do
    case pages |> Map.get(path) do
      nil -> pages
      page -> %{pages | path => _renew(page)}
    end
  end

  # Set Page.updated_at to now
  @spec _renew(Home.Page.t()) :: Home.Page.t()
  defp _renew(page)

  defp _renew(%Home.Page{} = page) do
    %Home.Page{page | updated_at: DateTime.utc_now()}
  end
end
