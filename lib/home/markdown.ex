defmodule Home.Markdown do
  @opts %Earmark.Options{
    gfm: true,
    breaks: false,
    code_class_prefix: "lang- language-",
    smartypants: false,
    postprocessor: &Home.Markdown.walker/1
  }
  def render(markdown, threshold \\ 6) do
    # Run Earmark in a separate task and collect events from it to build up the
    # ToC tree.

    {status, ast, msgs} = markdown |> Earmark.postprocessed_ast(@opts)
    toc_tree = Task.async(fn -> ast |> build_toc(threshold) end)
    html = Task.async(fn -> ast |> ast_to_html end)

    {{status, html |> Task.await(), msgs}, toc_tree |> Task.await()}
  end

  # A callback invoked as Earmark walks down the tree.
  def walker(ast)

  # <h1> receives a .title class
  def walker({"h1", attrs, inner, meta}) do
    classes = attrs |> List.keyfind("class", 0, {"class", ""}) |> elem(1) |> String.split()
    classes = ["title" | classes] |> Enum.uniq()
    attrs = attrs |> List.keyreplace("class", 0, {"class", classes})
    process_header({"h1", attrs, inner, meta})
  end

  # Match against any of the subheadings and send them to the headings processor.
  def walker({"h2", _, _, _} = ast), do: process_header(ast)
  def walker({"h3", _, _, _} = ast), do: process_header(ast)
  def walker({"h4", _, _, _} = ast), do: process_header(ast)
  def walker({"h5", _, _, _} = ast), do: process_header(ast)
  def walker({"h6", _, _, _} = ast), do: process_header(ast)

  # Attaches a `codeblock-LANG` class to `<pre>` tags that contain a tagged
  # `<code>` block.
  def walker({"pre", attrs, [{"code", code_attrs, _, _}] = inner, meta}) do
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
  def walker(ast), do: ast

  # Attach an anchoring identifier and inform the supervisor about it.
  def process_header({header, attrs, inner, meta}) do
    {anchor, rest} =
      case attrs |> List.keytake("id", 0) do
        # No `id` attr yet; create one from the text contents
        nil ->
          anchor = inner |> text_contents() |> to_snake()

          {anchor, attrs}

        # Existing `id` values are unchanged
        {{"id", anchor}, rest} ->
          {anchor, rest}
      end

    {classes, rest} =
      case rest |> List.keytake("class", 0) do
        nil -> {[], rest}
        {{"class", classes}, rest} -> {classes |> String.split(), rest}
      end

    classes = ["title" | classes] |> Enum.uniq()
    attrs = [{"class", classes |> Enum.join(" ")} | rest]

    case anchor do
      "" ->
        {header, attrs, inner, meta}

      anchor ->
        {header, [{"id", anchor} | attrs], inner, meta}
    end
  end

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

  def to_snake(text),
    do:
      text
      |> String.trim()
      |> String.downcase()
      |> String.replace(~r/\s+/, "-")
      |> String.trim("-")

  def extract_lang(classes),
    do:
      classes
      |> String.split()
      |> Enum.find("language-text", fn lang -> lang |> String.starts_with?("language-") end)
      |> String.trim_leading("language-")

  def build_toc(ast, threshold \\ 6) do
    ast
    |> flatten
    |> Enum.filter(fn rec -> keep_headings(rec, threshold) end)
    |> Enum.filter(fn {_, attrs, _, _} ->
      !(attrs
        |> List.keyfind("class", 0, {"class", ""})
        |> elem(1)
        |> String.split()
        |> Enum.any?(fn cls -> cls == "no-toc" end))
    end)
    |> Enum.map(fn {tag, attrs, html, _} ->
      {tag |> heading_to_rank, attrs |> List.keyfind("id", 0, {"id", ""}) |> elem(1), html}
    end)
    |> toc_tree()
  end

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
  than `threshold`.
  """
  def keep_headings({tag, _, _, _}, threshold \\ 6) do
    tag |> heading_to_rank <= threshold
  end

  def ast_to_html(ast), do: Earmark.Transform.transform(ast, @opts)

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
end
