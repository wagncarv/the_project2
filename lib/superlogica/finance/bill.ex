defmodule Superlogica.Finance.Bill do
  require Logger

  @keys_from_bill ["id_unidade_uni", "vl_total_recb", "dt_vencimento_recb"]

  def fields_from_bill(data, keys \\ @keys_from_bill) do
    Logger.info("#{__MODULE__}.fields_from_bill/2")

    keys
    |> Enum.reduce(%{}, fn field, map -> Map.put(map, field, Map.get(data, field)) end)
  end
end
