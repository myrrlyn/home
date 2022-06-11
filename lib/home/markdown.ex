defmodule Home.Markdown do
  @type toc_tree :: [toc_item]
  @type toc_item :: {String.t(), String.t(), toc_tree}

  @opts %Earmark.Options{
    gfm: true,
    breaks: false,
    code_class_prefix: "lang- language-",
    smartypants: false,
    postprocessor: &__MODULE__.walker/1
  }

  @doc """
  Renders a Markdown string, producing a table of contents as well as the HTML.

  ## Parameters

  - `markdown`: Any Markdown string.
  - `tocs`: A range, which must be equal to or within `1 .. 6`. This range
    filters which headings are included in the table of contents. As an example,
    blog posts may wish to set it to be `2 .. 3`, to exclude the title (`<h1>`),
    and include only the two highest remaining tiers.

  # Returns

  Currently, this assumes that the `markdown` is valid, and does not gracefully
  handle invalid Markdown.

  `{:ok, HTML, TOC, warnings}`, where HTML is a string of HTML text and TOC is
  a recursive list of `[name, ident, TOC]`.
  """
  def render(markdown, tocs \\ 1..6) do
    idents =
      case __MODULE__.Idents.start_link([]) do
        {:ok, agent} -> agent
        {:error, {:already_started, agent}} -> agent
        {:error, _} -> nil
      end

    {status, ast, msgs} =
      markdown
      |> Earmark.postprocessed_ast(%{
        @opts
        | postprocessor: fn node -> __MODULE__.walker(node, idents) end
      })

    case idents do
      nil -> nil
      pid -> pid |> __MODULE__.Idents.stop()
    end

    toc_tree = Task.async(fn -> ast |> build_toc(tocs) end)
    html = Task.async(fn -> ast |> ast_to_html() |> restore_tags() end)

    {status, html |> Task.await(), toc_tree |> Task.await(), msgs}
  end

  @doc """
  A callback invoked as Earmark walks down the tree.

  This receives an AST node from Earmark, and an optional PID of an identifier
  tracker. The identifier tracker holds encountered `id=` values, and can be
  used to turn an encountered identifier into a known-unique identifier in the
  document.

  ## Parameters

  Receives an Earmark AST node, and a PID of an identifier state keeper.

  ## Returns

  Returns an Earmark AST node.
  """
  @spec walker(Earmark.ast_node(), pid() | nil) :: Earmark.ast_node()
  def walker(ast, collector \\ nil)

  # Translate <blockquote role="complementary"> into <aside>
  def walker({"blockquote", attrs, inner, meta} = bq, _) do
    case attrs |> List.keytake("role", 0) do
      {{"role", "complementary"}, rest} -> {"aside", rest, inner, meta}
      _ -> bq
    end
  end

  # <h1> receives a .title class
  def walker({"h1", attrs, inner, meta}, collector) do
    classes = attrs |> List.keyfind("class", 0, {"class", ""}) |> elem(1) |> String.split()
    classes = ["title" | classes] |> Enum.uniq() |> Enum.join(" ")
    attrs = attrs |> List.keystore("class", 0, {"class", classes})
    process_header({"h1", attrs, inner, meta}, collector)
  end

  # Match against any of the subheadings and send them to the headings processor.
  def walker({"h2", _, _, _} = ast, collector), do: process_header(ast, collector)
  def walker({"h3", _, _, _} = ast, collector), do: process_header(ast, collector)
  def walker({"h4", _, _, _} = ast, collector), do: process_header(ast, collector)
  def walker({"h5", _, _, _} = ast, collector), do: process_header(ast, collector)
  def walker({"h6", _, _, _} = ast, collector), do: process_header(ast, collector)

  # Attaches a `codeblock-LANG` class to `<pre>` tags that contain a tagged
  # `<code>` block.
  def walker({"pre", attrs, [{"code", code_attrs, _, _}] = inner, meta}, _) do
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

    {"pre", [{"class", classes} | rest], inner, meta}
  end

  # Default clause does nothing
  def walker(ast, _), do: ast

  @doc """
  Ensures the header has a unique anchor in the document.
  """
  def process_header({header, attrs, inner, meta}, collector \\ nil) do
    {anchor, rest} =
      case attrs |> List.keytake("id", 0) do
        # No `id` attr yet; create one from the text contents
        nil ->
          anchor = inner |> text_contents() |> to_ident()
          {anchor, attrs}

        # Existing `id` values are unchanged
        {{"id", anchor}, rest} ->
          {anchor, rest}
      end

    anchor =
      case collector do
        nil -> anchor
        pid -> pid |> __MODULE__.Idents.identify(anchor)
      end

    {classes, rest} =
      case rest |> List.keytake("class", 0) do
        nil -> {[], rest}
        {{"class", classes}, rest} -> {classes |> String.split(), rest}
      end

    classes = classes |> Enum.uniq()
    attrs = [{"class", classes |> Enum.join(" ")} | rest]

    case anchor do
      "" ->
        {header, attrs, inner, meta}

      anchor ->
        {header, [{"id", anchor} | attrs], inner, meta}
    end
  end

  @doc """
  Extracts only the text contents of an HTML node and its children.
  """
  def text_contents(ast), do: ast |> text_contents_inner |> List.flatten() |> Enum.join(" ")

  def text_contents_inner(ast)

  def text_contents_inner([]), do: []

  def text_contents_inner([head | tail]) do
    [
      head |> text_contents_inner()
      | tail |> text_contents_inner()
    ]
  end

  def text_contents_inner(text) when is_binary(text),
    do: [text |> String.trim()]

  def text_contents_inner({_, _, inner, _}), do: text_contents_inner(inner)

  @doc """
  Degrades a text span into an HTML anchor name.
  """
  def to_ident(text),
    do:
      text
      |> String.trim()
      |> String.downcase()
      |> String.replace(~r/\s+/u, "-")
      |> String.replace(~r/[^\w-]/u, "")
      |> String.trim("-")

  @doc """
  Computes the source language of a code block.
  """
  def extract_lang(classes),
    do:
      classes
      |> String.split()
      |> Enum.find("language-text", fn lang -> lang |> String.starts_with?("language-") end)
      |> String.trim_leading("language-")

  @doc """
  Builds a table of contents out of a parsed AST.

  This function:

  - flattens the tree into a stream
  - ignores all non-heading nodes
  - computes the text contents of the heading, ignoring punctuation and style
    nodes
  - generates a unique identifier from the text contents, or existing ident if
    provided
  - then reshapes the list of headings back into a tree

  ## Parameters

  - `ast`: A parsed Earmark AST.
  - `tocs`: A range of which headings are preserved in the output TOC.

  ## Returns

  `TOC`, where `TOC ` is `[name, ident, TOC]`
  """
  def build_toc(ast, tocs \\ 1..6) do
    ast
    |> flatten()
    |> Stream.filter(fn rec -> keep_headings(rec, tocs) end)
    |> Stream.filter(fn {_, attrs, _, _} ->
      !(attrs
        |> List.keyfind("class", 0, {"class", ""})
        |> elem(1)
        |> String.split()
        |> Enum.any?(fn cls -> cls == "no-toc" end))
    end)
    |> Stream.map(fn {tag, attrs, html, _} ->
      {tag |> heading_to_rank, attrs |> List.keyfind("id", 0, {"id", ""}) |> elem(1), html}
    end)
    |> Enum.to_list()
    |> toc_tree()
  end

  @doc """
  Flattens an AST tree into a list. The tree

  1. root
     1. contents 0
     1. tag A
        1. contents 1
        1. tag C
           1. contents 2
        1. tag D
           1. contents 3
     1. tag B
        1. contents 4
        1. tag E
           1. contents 5
        1. tag D
           1. contents 6

  becomes the list

  1. root
  1. contents 0
  1. tag A
  1. contents 1
  1. tag C
  1. contents 2
  1. tag D
  1. contents 3
  1. tag B
  1. contents 4
  1. tag E
  1. contents 5
  1. tag D
  1. contents 6

  The *contents* of each AST node are moved out of it and appended to the list,
  leaving a now-empty node in its original position.
  """
  def flatten(ast)

  def flatten([]), do: []
  def flatten([text | rest]) when is_binary(text), do: flatten(rest)

  def flatten([{tag, attrs, inner, meta} | rest]) do
    [
      {tag, attrs, inner |> ast_to_html(), meta}
      | flatten(inner)
    ] ++ flatten(rest)
  end

  @doc """
  Discards all nodes in an `Earmark.ast` that are not headings of lower rank
  than `tocs`.
  """
  def keep_headings({tag, _, _, _}, tocs \\ 1..6) do
    Enum.member?(tocs, tag |> heading_to_rank)
  end

  def ast_to_html(ast), do: Earmark.Transform.transform(ast, @opts)

  @doc """
  Un-escapes certain tags. Does not support attributes in those tags.

  This is not aware of context, and replaces *all* escaped tag instances.
  """
  def restore_tags(html) do
    tags = [
      "br",
      "br /",
      "cite",
      "code",
      "del",
      "dfn",
      "ins",
      "kbd",
      "key",
      # "math",
      # "mfrac",
      # "mi",
      # "mo",
      # "mn",
      # "msub",
      # "msup",
      "small",
      "sub",
      "sup"
    ]

    re = ~r/&lt;(?<c>\/)?(?<t>#{tags |> Enum.join("|")})&gt;/

    Regex.replace(
      re,
      html,
      "<\\1\\2>"
    )
  end

  @doc """
  Converts `"<hN>"` to `N`
  """
  def heading_to_rank(tag) do
    case tag do
      "h1" -> 1
      "h2" -> 2
      "h3" -> 3
      "h4" -> 4
      "h5" -> 5
      "h6" -> 6
      _ -> 7
    end
  end

  @doc """
  Builds a tree out of a flat list of headings.

  Given a sequence of headings in source order, this produces a tree structure
  that can be used to produce HTML lists.
  """
  def toc_tree(headings)

  def toc_tree([]), do: []

  def toc_tree(headings) do
    {head, tail} = headings |> split_headings
    (head |> make_tree()) ++ (tail |> toc_tree())
  end

  @doc """
  Given a list of heading records, splits the list into a tree and a remnant.

  A "tree" is defined as a sublist where, if it has more than one element, all
  elements *after* `head` have rank greater than `head`.
  """
  def split_headings(hs)
  def split_headings([]), do: {[], []}
  def split_headings([h]), do: {[h], []}

  def split_headings([{rank, _, _} | rest] = hs) when is_list(hs) do
    # Find the index of the first h that is not subordinate to the head
    split = rest |> Enum.find_index(fn {r, _, _} -> r <= rank end)

    # If there is a peer or superior heading, split the list at that point
    if split do
      # The index is of `rest`, but we are splitting `hs`
      hs |> Enum.split(split + 1)
    else
      {hs, []}
    end
  end

  @doc """
  Converts a flat list of headings into a tree of children (higher rank than
  `head`) and siblings (equal rank to `head`). This may only be called on lists
  that have been chunked so that in `[head | rest]`, no record in `rest` has
  lower rank than `head`.
  """
  def make_tree(hs)

  def make_tree([]), do: []
  def make_tree([{_, path, show}]), do: [{show, path, []}]

  def make_tree([{a, path, show} | [{b, _, _} | _] = tail]) do
    if b > a do
      [{show, path, toc_tree(tail)}]
    else
      [{show, path, []} | toc_tree(tail)]
    end
  end

  defmodule Idents do
    @moduledoc """
    Tracks which identifiers have been encountered during a document traversal.

    `id=` attributes must have their values be unique in a document. Traversals
    that expect to encounter or generate `id=` attributes should use this module
    as a transform filter on their encountered or generated identifiers.

    The first time it encounters an identifier, it returns the identifier
    unchanged. All subsequent encounters of that identifier are suffixed with
    an incrementing counter.
    """
    use Agent

    @doc """
    Starts up a new, fresh, collector.
    """
    def start_link(_opts \\ []), do: Agent.start_link(fn -> %{} end)

    @doc """
    Submits an identifier to the collector.

    ## Parameters

    - `this`: The PID for a particular instance.
    - `ident`: The identifier being submitted.

    ## Returns

    A unique identifier string.
    """
    def identify(this, ident) do
      this
      |> Agent.get_and_update(fn idents ->
        case idents |> Map.get(ident) do
          nil ->
            {ident, idents |> Map.put(ident, 1)}

          n ->
            {"#{ident}-#{n}", %{idents | ident => n + 1}}
        end
      end)
    end

    @doc """
    Resets the collector to the blank state.
    """
    def reset(this) do
      this |> Agent.update(fn _ -> %{} end)
    end

    @doc """
    Terminates the collector.
    """
    def stop(this), do: Agent.stop(this)
  end
end
