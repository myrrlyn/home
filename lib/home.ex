defmodule Home do
  @moduledoc """
  Home keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def rotate_avi do
    clock_random()
  end

  defp true_random, do: 0..359 |> Enum.random()

  defp normal_random, do: Statistics.Distributions.Normal.rand(0, 60) |> round()

  defp calendar_random, do: Date.utc_today().day * 12

  defp clock_random, do: Time.utc_now() |> Time.to_seconds_after_midnight() |> elem(0) |> div(240)
end
