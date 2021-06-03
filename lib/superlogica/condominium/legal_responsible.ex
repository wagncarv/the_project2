
defmodule Superlogica.Condominium.LegalResponsibles do
  require Logger
  alias Superlogica.Helpers.{Headers, Helpers}

  # cabeçalho com parâmetros obrigatórios
  @headers Headers.headers()

  @keys_params ["idCondominio", "comStatus"]

  @responsibles_fields [
    {"st_cargo_sin", "occupation"},
    {"st_telefone_sin", "phone"},
    {"st_nome_cond", "condominium"},
    {"st_nome_sin", "name"},
    {"st_celular_sin", "cellphone"},
    {"aremails", "email"},
    {"id_condominio_cond", "condominium_id"}
  ]

  @endpoint "https://api.superlogica.net/v2/condor/sindicos?"

  def list_all(condominium_id \\ 2, status \\ "atuais") do
    params = Helpers.build_query_params(@keys_params, [condominium_id, status])
    HTTPoison.get!("#{@endpoint}#{params}", @headers)
    |> handle_list_all()
  end

  def formatted_legal_responsibles(condominium_id) do
    list_all(condominium_id)
    |> Enum.reduce("*Responsáveis legais do condomínio*:\n", fn %{"name" => name, "occupation" => occupation, "cellphone" => cellphone, "email" => email}, str ->
      "#{str}Nome: #{name}\nCargo: #{occupation}\nCelular: #{cellphone}\nE-mail: #{email}\n\n"
    end)
  end

  def by_occupation(condominium_id, occupation \\ "Síndico") do
    list_all(condominium_id)
    |> Enum.filter(fn %{"occupation" => in_charge} -> in_charge == occupation end)
  end

  def formatted_by_occupation(condominium_id, occupation \\ "Síndico") do
    by_occupation(condominium_id, occupation)
    |> Enum.reduce("", fn %{"occupation" => occupation, "name" => name, "cellphone" => cellphone, "email" => email}, str ->
      "#{str}*Responsável legal*:\nNome: #{name}\nCargo: #{occupation}\nTelefone: #{cellphone}\nE-mail: #{email}\n"
    end)
  end

  defp handle_list_all(%HTTPoison.Response{body: body}) do
    body
    |> Jason.decode()
    |> elem(1)
    |> Stream.map(fn e -> get_fields(e) end)
    |> Enum.map(fn e ->
      Map.put(e, "email", Enum.join(e["email"], ", "))
    end)
  end

  defp get_fields(responsible) do
    @responsibles_fields
    |> Enum.reduce(%{}, fn {key, new_key}, map ->
      Map.put(map, new_key, Map.get(responsible, key))
    end)
  end
end
