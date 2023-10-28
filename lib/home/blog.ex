defmodule Home.Blog do
  @moduledoc """
  Support utilities for working with blog files and URL paths.
  """

  @re_date ~r/(?<y>[[:digit:]]{4})-(?<m>[[:digit:]]{2})-(?<d>[[:digit:]]{2})/
  @re_full ~r/^(#{@re_date.source}-)?(?<title>.+)$/

  @doc """
  Splits a filename into date and title sections.
  """
  def split_date_title(path) do
    name = path |> Path.basename() |> Path.rootname()
    Regex.named_captures(@re_full, name)
  end

  @doc """
  Gets the date out of a blog's filename and parsed contents.
  """
  def get_date_for({path, yml}) do
    case yml |> Map.get("date") do
      nil -> path |> split_date_title()
      date -> Regex.named_captures(@re_date, date)
    end
    |> Map.delete("title")
    |> (fn %{"y" => y, "m" => m, "d" => d} -> [y, m, d] |> Enum.join("-") end).()
  end

  @spec walkdir(Path.t()) :: Enumerable.t(Path.t())
  def walkdir(root) do
    [root, "**", "*.md"]
    |> Path.join()
    |> Path.wildcard()
    |> Stream.filter(&File.regular?/1)
    |> Stream.reject(&(Path.basename(&1) in ["index.md", "README.md"]))
    |> Stream.map(&Path.relative_to(&1, "priv/pages"))
  end
end
