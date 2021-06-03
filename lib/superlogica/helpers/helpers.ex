defmodule Superlogica.Helpers.Helpers do
  require Logger

  def build_body(keys, values) do
    Enum.zip(keys, values)
    |> Enum.reduce(%{}, fn {key, value}, map -> Map.put(map, key, value) end)
  end

  # query params
  def build_query_params(key_params, value_params) do
    build_body(key_params, value_params)
    |> URI.encode_query()
  end

  def plural_or_singular(message, value) do
    case value do
      0 -> singularize_debts_message(message)
      _ -> pluralize_debts_message(message)
    end
  end

  #
  defp pluralize_debts_message(message), do: String.replace(message, ~r/\(|\)/, "")
  defp singularize_debts_message(message), do: String.replace(message, ~r/\([ms]\)/, "")

  def build_message(message, values \\ [], patterns \\ []) do
    IO.inspect(values)
    IO.inspect(patterns)

    Enum.zip(values, patterns)
    |> Enum.reduce(message, fn {value, expr}, message -> String.replace(message, expr, value) end)
  end

  def pop_key(keys, key) do
    Enum.filter(keys, fn e -> e == key end)
  end
end
