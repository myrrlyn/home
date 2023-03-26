defmodule Home.Banners.Banner do
  @moduledoc """
  A banner object, including the image and its display properties.
  """
  defstruct file: nil,
            tags: [],
            caption: nil,
            freq: 1,
            pos: {:center, :center},
            dim: [height: 128]

  @type t :: %__MODULE__{
          file: Path.t() | nil,
          tags: [atom()],
          caption: String.t() | nil,
          freq: pos_integer(),
          pos: {atom() | String.t(), atom() | String.t()},
          dim: [height: pos_integer()] | [width: pos_integer(), height: pos_integer()] | nil
        }

  def position(%__MODULE__{pos: {x, y}}) do
    "#{x} #{y}"
  end

  def style_rules(%__MODULE__{pos: {x, y}, dim: [{:width, width}, {:height, height}]}) do
    "aspect-ratio: #{width} / #{height};"
  end

  def style_rules(%__MODULE__{dim: [{:height, height}]}) do
    "height: #{height}px;"
  end

  def style_rules(%__MODULE__{}) do
    ""
  end

  def new(%{file: file, caption: caption} = attrs) do
    {tags, attrs} = attrs |> Map.pop(:tags, [])
    {freq, attrs} = attrs |> Map.pop(:freq, 1)
    {pos, attrs} = attrs |> Map.pop(:pos, {:center, :center})
    {dim, _attrs} = attrs |> Map.pop(:dim, [{:height, 128}])

    %__MODULE__{
      caption: caption,
      file: file,
      tags: tags,
      freq: freq,
      pos: pos,
      dim: dim
    }
  end
end

defmodule Home.Banners.TomlTransform do
  @moduledoc """
  Helper functions to turn bare TOML values into more structured data.
  """

  use Toml.Transform

  def transform(:pos, %{x: x, y: y} = pos) when is_map(pos) do
    x =
      case x do
        "left" -> :left
        "center" -> :center
        "right" -> :right
        other -> other
      end

    y =
      case y do
        "top" -> :top
        "center" -> :center
        "bottom" -> :bottom
        other -> other
      end

    {x, y}
  end

  def transform(:pos, pos) do
    {:error, {:invalid_position, pos, :expected_x_y_pair}}
  end

  def transform(:dim, %{width: width, height: height} = pos) when is_map(pos) do
    [{:width, width}, {:height, height}]
  end

  def transform(:dim, %{height: h} = pos) when is_map(pos) do
    [{:height, h}]
  end

  def transform(:dim, dim) do
    {:error, {:invalid_dimensions, dim, :expected_height_or_width_height_pair}}
  end

  def transform(:tags, tags) when is_list(tags) do
    for tag <- tags do
      String.to_atom(tag)
    end
  end

  def transform(:tags, tags) do
    {:error, {:invalid_tags, tags, :expected_list_of_strings}}
  end

  def transform(:banners, all_banners) when is_map(all_banners) do
    prepend_album = fn album, %{file: file} = object ->
      Home.Banners.Banner.new(%{object | file: Path.join(album |> to_string(), file)})
    end

    for {album, banners} <- all_banners do
      case banners do
        named when is_map(named) ->
          {album,
           named
           |> Enum.map(fn {name, object} ->
             {name, prepend_album.(album, object)}
           end)
           |> Enum.into(%{})}

        unnamed when is_list(unnamed) ->
          {album,
           unnamed
           |> Enum.map(fn object ->
             prepend_album.(album, object)
           end)
           |> Enum.into([])}

        _ ->
          raise "unexpected collection"
      end
    end
    |> Enum.into(%{})
  end

  def transform(:banners, banners) do
    {:error, {:invalid_banners, banners, :expected_banner_struct}}
  end

  def transform(_key, value), do: value
end

defmodule Home.Banners do
  @moduledoc """
  Source material for banner images.
  """

  @type album_unnamed :: [__MODULE__.Banner.t()]
  @type album_named :: %{atom() => __MODULE__.Banner.t()}
  @type album :: album_named() | album_unnamed()
  @type banners :: Enumerable.t(__MODULE__.Banner.t())

  @doc """
  A collection of known banner objects generated at compile-time.
  """
  @banners ["assets", "banners.toml"]
           |> Path.join()
           |> File.stream!()
           |> Toml.decode_stream!(keys: :atoms, transforms: [__MODULE__.TomlTransform])

  @doc """
  Loads the banner collection information from disk.
  """
  def load_banners(),
    do:
      ["assets", "banners.toml"]
      |> Path.join()
      |> File.stream!()
      |> Toml.decode_stream!(keys: :atoms, transforms: [__MODULE__.TomlTransform])

  @doc """
  Produces all banners, grouped by their album.
  """
  @spec all_banners :: %{atom() => album()}
  def all_banners(), do: @banners[:banners]

  @doc """
  Produces the dictionary of album identifiers to display names.
  """
  @spec albums :: %{atom() => String.t()}
  def albums(), do: @banners[:albums]

  @spec album_name(atom() | String.t()) :: String.t()
  def album_name(name) when is_atom(name) do
    Map.get(albums(), name, "[Unknown Album]")
  end

  def album_name(name) when is_binary(name) do
    names = albums() |> Map.keys() |> Enum.map(&to_string/1)

    if Enum.member?(names, name) do
      albums()[name |> String.to_atom()]
    else
      "[Unknown Album]"
    end
  end

  @doc """
  Produces all banners except those from /r/teslore.
  """
  @spec main_banners :: %{atom() => album_unnamed()}
  def main_banners() do
    all_banners() |> Map.drop([:teslore])
  end

  @doc """
  Produces only the /r/teslore banners.
  """
  @spec teslore_banners :: album_named()
  def teslore_banners() do
    all_banners()[:teslore]
  end

  @doc """
  Produces a flat stream of all banners, without any album grouping.
  """
  @spec make_stream(%{atom() => album()}) :: banners()
  def make_stream(banners) do
    banners
    |> Map.values()
    |> Stream.flat_map(fn album ->
      case album do
        unnamed when is_list(unnamed) ->
          unnamed

        named when is_map(named) ->
          named |> Map.values()

        _ ->
          []
      end
    end)
  end

  @doc """
  Gets a set of all tags listed in the banners collection.
  """
  @spec get_tags :: [atom()]
  def get_tags() do
    all_banners()
    |> make_stream()
    |> Stream.flat_map(fn %__MODULE__.Banner{tags: tags} -> tags end)
    |> Enum.into(MapSet.new())
    |> Enum.to_list()
  end

  @doc """
  Selects banners from an input stream that match a given tag.

  The input stream must be flat, as is the output stream.
  """
  @spec filter_tags(banners(), [atom() | String.t()] | nil) :: banners()
  def filter_tags(banners, tagset \\ nil)
  def filter_tags(banners, nil), do: banners
  def filter_tags(banners, tag) when is_binary(tag), do: filter_tags(banners, [tag])

  def filter_tags(banners, tagset) when is_list(tagset) do
    banners
    |> Stream.filter(fn %__MODULE__.Banner{tags: tags} ->
      tagset = tagset |> Enum.map(&to_string/1) |> Enum.into(MapSet.new())
      tags = tags |> Enum.map(&to_string/1) |> Enum.into(MapSet.new())
      MapSet.intersection(tagset, tags) != MapSet.new()
    end)
  end

  @doc """
  Gets a true-random banner from a collection.

  The collection can be `:main_banners`, one of the album names as either an
  atom or a string, or an `Enumerable` of `Banner{}` structs. If a tag is
  provided, then the input collection is filtered down by that tag.
  """
  @spec true_random(atom() | String.t() | banners(), atom() | nil) :: __MODULE__.Banner.t()
  def true_random(album_or_banners, tag \\ nil)

  def true_random(:main_banners, tag) do
    main_banners() |> make_stream() |> true_random(tag)
  end

  def true_random(album_name, tag) when is_atom(album_name) do
    main_banners() |> Map.get(album_name, :misc) |> true_random(tag)
  end

  def true_random(album_name, tag) when is_binary(album_name) do
    if albums() |> Map.keys() |> Enum.map(&to_string/1) |> Enum.member?(album_name) do
      true_random(album_name |> String.to_atom(), tag)
    else
      true_random(:main_banners, tag)
    end
  end

  def true_random(banners, tag) do
    filtered = banners |> filter_tags(tag) |> Enum.to_list()
    idx = filtered |> length() |> :rand.uniform()
    Enum.at(filtered, idx - 1)
  end

  @doc """
  Gets a weighted-random banner from a collection.

  The collection can be `:main_banners`, one of the album names as either an
  atom or a string, or an `Enumerable` of `Banner{}` structs. If a tag is
  provided, then the input collection is filtered down by that tag.

  The banners that survive selection and filtering are weighted by their `.freq`
  attribute.
  """
  @spec weighted_random(atom() | String.t() | banners(), [atom()] | [String.t()] | nil) ::
          __MODULE__.Banner.t()
  def weighted_random(album_or_banners, tags \\ nil)

  def weighted_random(:main_banners, tags) do
    main_banners() |> make_stream() |> weighted_random(tags)
  end

  def weighted_random(album_name, tags) when is_atom(album_name) do
    main_banners() |> Map.get(album_name, :misc) |> weighted_random(tags)
  end

  def weighted_random(album_name, tags) when is_binary(album_name) do
    if albums() |> Map.keys() |> Enum.map(&to_string/1) |> Enum.member?(album_name) do
      weighted_random(album_name |> String.to_atom(), tags)
    else
      weighted_random(:main_banners, tags)
    end
  end

  def weighted_random(banners, tags) do
    banners =
      banners
      |> filter_tags(tags)

    idx =
      banners
      |> Stream.map(fn %__MODULE__.Banner{freq: freq} -> freq end)
      |> Enum.reduce(&(&1 + &2))
      |> :rand.uniform()
      |> (&(&1 - 1)).()

    %__MODULE__.Banner{} =
      out =
      banners
      |> Stream.map(&{&1, &1.freq})
      |> Enum.reduce(fn {next, weight}, {prev, sum} ->
        step = sum + weight
        # Advance the image until the index is less than the cursor, then freeze.
        if idx > step do
          {next, step}
        else
          {prev, step}
        end
      end)
      |> elem(0)

    out
  end

  @doc """
  Gets a random banner from the given album.
  """
  @spec random_from_album(String.t()) :: __MODULE__.Banner.t()
  def random_from_album(album_id) do
    album_id = get_album_id(album_id)

    banners =
      case main_banners()[album_id] do
        unnamed when is_list(unnamed) -> unnamed
        named when is_map(named) -> named |> Map.values()
        _ -> :main_banners
      end

    weighted_random(banners)
  end

  @doc """
  Gets a random image from the set of banners that have the given tag.
  """
  @spec random_from_tags([String.t()] | nil) :: __MODULE__.Banner.t()
  def random_from_tags(tags) do
    main_banners() |> make_stream() |> filter_tags(tags) |> true_random()
  end

  @doc """
  If the frontmatter provides an `album:` (and optionally `image:`) key, this
  fetches the specified (or a random) banner from the album. If the keys do not
  name an existing entry, a random banner is selected instead, using the
  optional `album_id` and `tag` arguments to filter the collection.
  """
  def select_or_random(%Home.Meta{props: props}, album_id \\ :main_banners, tags \\ nil) do
    case get_album_id(props["album"]) do
      :main_banners ->
        nil

      album ->
        if key = props["image"] do
          case {main_banners()[album], key} do
            {unnamed, idx} when is_list(unnamed) and is_integer(idx) ->
              throw(Enum.at(unnamed, key))

            {named, key} when is_map(named) and is_binary(key) ->
              throw(named[key])
          end
        else
          throw(random_from_album(album_id))
        end
    end

    throw(
      case(props["banner_tags"]) do
        nil -> nil
        tags when is_list(tags) -> random_from_tags(tags)
        tag when is_binary(tag) -> random_from_tags([tag])
      end
    )
  catch
    nil -> weighted_random(album_id, tags)
    thrown -> thrown
  end

  @doc """
  Gets a named banner from the TESLore collection.
  """
  @spec teslore(String.t()) :: __MODULE__.Banner.t()
  def teslore(name) do
    banners =
      teslore_banners()
      |> Stream.map(fn {k, banner} -> {k |> to_string, banner} end)
      |> Enum.into(%{})

    Map.get(
      banners,
      name,
      banners["text-oghma"]
    )
  end

  @spec get_album_id(String.t()) :: atom()
  defp get_album_id(album_id) when is_binary(album_id) do
    lookup = albums() |> Enum.map(fn {k, _} -> {to_string(k), k} end) |> Enum.into(%{})
    Map.get(lookup, album_id, :main_banners)
  end

  defp get_album_id(:main_banners), do: :main_banners

  defp get_album_id(nil), do: :main_banners
end

defimpl Phoenix.Param, for: Home.Banners.Banner do
  def to_param(%Home.Banners.Banner{} = banner) do
    to_string(banner)
  end
end

defimpl String.Chars, for: Home.Banners.Banner do
  def to_string(%Home.Banners.Banner{file: file}) do
    ["static", "images", "banners", file] |> Path.join()
  end
end
