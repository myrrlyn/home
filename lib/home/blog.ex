defmodule Home.Blog do
  @re_date ~r/(?<y>[[:digit:]]{4})-(?<m>[[:digit:]]{2})-(?<d>[[:digit:]]{2})/
  @re_full ~r/^(#{@re_date.source}-)?(?<title>.+)$/
  def split_date_title(path) do
    name = path |> Path.basename() |> Path.rootname()
    Regex.named_captures(@re_full, name)
  end

  def get_date_for({path, yml}) do
    case yml |> Map.get("date") do
      nil -> path |> split_date_title()
      date -> Regex.named_captures(@re_date, date)
    end
    |> Map.delete("title")
    |> (fn %{"y" => y, "m" => m, "d" => d} -> [y, m, d] |> Enum.join("-") end).()
  end
end
