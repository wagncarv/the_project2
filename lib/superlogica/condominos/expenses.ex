defmodule Superlogica.Condominos.Expenses do
  require Logger
  alias Superlogica.Helpers.{ChronoUnit, Headers, Helpers}
  alias Superlogica.Condominos.Condominos

  @endpoint "https://api.superlogica.net/v2/condor/cobranca/index?"
  @nonpayment_endpoint "https://api.superlogica.net/v2/condor/inadimplencia/index?"

  @headers Headers.headers()

  @header_params [
    "status",
    "apenasColunasPrincipais",
    "exibirPgtoComDiferenca",
    "comContatosDaUnidade",
    "id_condominium",
    "dtInicio",
    "dtFim",
    "UNIDADES"
  ]

  @header_params_not_payed [
    "id",
    "idCondominio",
    "cobrancaDoTipo",
    "posicaoEm",
    "comValoresAtualizados",
    "comValoresAtualizadosPorComposicao",
    "apenasResumoInad",
    "comDadosDaReceita",
    "itensPorPagina",
    "pagina",
    "semAcordo",
    "semProcesso"
  ]

  @default_values_not_payed [0, 1, 0, 1, 50, 1, 1, 0]
  #
  def list_expenses(
        apartment_id,
        begin_date,
        end_date,
        condominium_id \\ 2,
        status \\ "pendentes",
        url \\ @endpoint
      ) do

    query_params =
      Helpers.build_query_params(@header_params, [
        status,
        "1",
        "1",
        "1",
        condominium_id,
        begin_date,
        end_date,
        apartment_id
      ])
      |> String.replace(~r/UNIDADES=/, "UNIDADES[#{apartment_id}]=")

    HTTPoison.get("#{url}#{query_params}", @headers)
    |> handle_list_expenses()
  end

  @doc """
  Através do telefone, busca condômino em todos os condomínios,
  consulta as despesas do condômino encontrado e as ordena por
  data decrescente.

  ## Parameters

    `phone`: String que representa um número de telefone
  """
  def by_phone(
        number,
        begin_date \\ ChronoUnit.beginning_of_year(),
        end_date \\ ChronoUnit.today()
      ) do

    case Condominos.find_anywhere("#{number}") do
      {:error, "resident not found"} ->
        {:error, "debts not found"}

      [%{"id_unidade_uni" => apartment_id, "id_condominio_cond" => condominium_id} | _] ->
        list_expenses(apartment_id, begin_date, end_date, condominium_id)
        |> Stream.map(fn item ->
          Map.put(item, "dt_vencimento_recb", ChronoUnit.convert(item["dt_vencimento_recb"]))
        end)
        |> Enum.sort(fn head, tail ->
          head["dt_vencimento_recb"] < tail["dt_vencimento_recb"]
        end)
    end
  end

  def nonpayment(
        apartment_id,
        condominium_id \\ 2,
        billing_type \\ "inadimplente",
        status_now \\ ChronoUnit.custom_today()
      ) do

    query_params =
      Helpers.build_query_params(
        @header_params_not_payed,
        [apartment_id, condominium_id, billing_type, status_now] ++ @default_values_not_payed
      )

    HTTPoison.get("#{@nonpayment_endpoint}#{query_params}", @headers)
    |> handle_nonpayment()
  end

  defp handle_list_expenses({:ok, %HTTPoison.Response{body: body}}) do
    body
    |> Jason.decode()
    |> elem(1)
  end

  defp handle_nonpayment({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
    {_, values} =
      body
      |> Jason.decode()

    reduce_values(values)
  end

  defp reduce_values(list) do
    list
    |> Stream.map(fn %{"recebimento" => values} -> values end)
    |> Enum.into([])
    |> List.flatten()
    |> Stream.map(fn %{"dt_vencimento_recb" => expiry, "receitas" => values} ->
      {expiry, values}
    end)
    |> Enum.map(fn {expiry, values} -> {expiry, collect(values)} end)
    |> Enum.into(%{})
  end

  defp collect(list) do
    list
    |> Enum.map(fn %{"encargos" => values} -> values end)
    |> List.flatten()
    |> Enum.map(fn %{
                     "diasatraso" => delay_days,
                     "mesesatraso" => delay_months,
                     "valorcorrigido" => value
                   } ->
      %{"diasatraso" => delay_days, "mesesatraso" => delay_months, "valorcorrigido" => value}
    end)
  end
end
