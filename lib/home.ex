defmodule Home do
  @moduledoc """
  Home keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def rotate_avi do
    calendar()
  end

  @doc "Converts a string to an HTML-acceptable identifier."
  def str_to_ident(text) do
    text
    |> String.downcase()
    |> String.replace(~r/[^\w ]+/, "")
    |> String.replace(~r/\s+/, "-")
  end

  def is_symlink(path) do
    case path |> File.read_link() do
      {:ok, _} -> true
      {:error, :einval} -> false
      {:error, _} -> false
    end
  end

  @doc "Generates a random image rotation"
  def true_random, do: 0..359 |> Enum.random()

  @doc "Generates a random image rotation, tending to near vertical"
  def normal_random, do: Statistics.Distributions.Normal.rand(0, 60) |> round()

  @doc "Produces a rotation by the day of the month"
  def calendar, do: Date.utc_today().day * 12

  @doc "Produces a rotation by the second of the day"
  def clock, do: Time.utc_now() |> Time.to_seconds_after_midnight() |> elem(0) |> div(240)
end
