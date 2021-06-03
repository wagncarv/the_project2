defmodule Superlogica.Condominium.Condominium do
  require Logger
  alias Superlogica.Helpers.{Headers, Helpers}

  # cabeçalho com parâmetros obrigatórios
  @headers Headers.headers()

  @endpoint "https://api.superlogica.net/v2/condor/condominios/get?"

  @keys_params [
    "id",
    "somenteCondominiosAtivos",
    "ignorarCondominioModelo",
    "apenasColunasPrincipais",
    "comDadosFechamento",
    "apenasDadosDoPlanoDeContas",
    "comDataFechamento"
  ]

  @keys_params_values [-1, 1, 1, 1, 1, 0, 1]

  def list_all(keys_params \\ @keys_params, keys_values \\ @keys_params_values) do
    params = Helpers.build_query_params(keys_params, keys_values)

    "#{@endpoint}#{params}"
    |> HTTPoison.get(@headers)
    |> handle_list_all()
  end

  def list_all_by_name_and_id do
    list_all()
    |> Enum.map(fn %{"id_condominio_cond" => id, "st_nome_cond" => name} ->
      %{"name" => name, "id" => id}
    end)
  end

  defp handle_list_all({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
    body
    |> Jason.decode()
    |> elem(1)
  end

  defp handle_list_all({:ok, %HTTPoison.Response{body: body, status_code: 404}}) do
    message =
      body
      |> Jason.decode()
      |> elem(1)

    {:error, message}
  end

  defp handle_list_all({:error, %HTTPoison.Error{id: nil, reason: :timeout}}), do: {:error, :timeout}

  def by_id(condominium_id) do
    list_all_by_name_and_id()
    |> Enum.filter(fn %{"id" => id} -> id == "#{condominium_id}" end)
  end
end
