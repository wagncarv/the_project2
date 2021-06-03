defmodule Superlogica.Condominos.Condominos do
  require Logger
  alias Superlogica.Helpers.{Headers, Helpers}
  alias Superlogica.Condominium.Condominium

  @endpoint "https://api.superlogica.net/v2/condor/responsaveis/"
  @keys_params ["idCondominio", "ordenacao", "itensPorPagina", "pagina"]

  # cabeçalho com parâmetros obrigatórios
  @headers Headers.headers()

  @keys_resident_profile ["st_telefone_con", "st_nome_con"]
  @keys_profile_by_phone [
    {"st_bloco_uni", "apartment_block"},
    {"st_rg_con", "rg"},
    {"st_telefone_con", "phone"},
    {"st_unidade_uni", "apartment_number"},
    {"id_unidade_uni", "apartment_id"},
    {"id_condominio_cond", "condominium_id"},
    {"st_email_con", "email"},
    {"st_cpf_con", "cpf"},
    {"st_nometiporesp_tres", "resident"},
    {"st_nome_con", "name"}
  ]

  @doc """
  Lista todos os condôminos do condomínio passado como parâmetro

  ## Parameters

    `id_condominium`: String que representa um número de condomínio
    `itens_per_page`: String que representa itens exibidos por página
    `page`: String que representa o número de páginas
  """
  def list_all(id_condominium \\ 2, itens_per_page \\ 50, page \\ 1) do
    query_params =
      Helpers.build_query_params(@keys_params, [
        id_condominium,
        "ST_NOME_CON ASC",
        itens_per_page,
        page
      ])

    "#{@endpoint}index?#{query_params}"
    |> HTTPoison.get(@headers)
    |> handle_list_all()
  end

  @doc """
  Através do telefone, busca condômino em todos os condomínios

  ## Parameters

    `phone`: String que representa um número de telefone
  """
  def find_anywhere(phone) do
    Condominium.list_all_by_name_and_id()
    |> Enum.map(fn %{"id" => id} ->
      list_all(id)
      |> Enum.find(fn %{"st_telefone_con" => number} -> number == phone end)
    end)
    |> handle_find_anywhere()
  end

  @doc """
  Busca condômino pelo id da habitação

  ## Parameters

    `room_id`: String que representa o id da habitação
    `id_condominium`: id do condomínio
  """
  def by_room_id(room_id, id_condominium \\ 2) do
    list_all(id_condominium)
    |> Enum.filter(fn e -> e["id_unidade_uni"] == "#{room_id}" end)
  end

  @doc """
  Busca condômino pelo telefone

  ## Parameters

    `phone_number`: String que representa o número de telefone do condômino
    `id_condominium`: String que representa o id do condomínio
  """
  def by_phone(phone_number, id_condominium \\ 2) do
    list_all(id_condominium)
    |> Enum.filter(fn e -> e["st_telefone_con"] == "#{phone_number}" end)
  end

  @doc """
  Busca condômino pelo cpf

  ## Parameters

    `id`: String que representa o número do cpf do condômino
    `id_condominium`: String que representa o id do condomínio
  """
  def by_cpf(id, id_condominium \\ 2) do
    list_all(id_condominium)
    |> Enum.filter(fn e -> e["st_cpf_con"] == "#{id}" end)
    |> hd()
  end

  @doc """
  Busca número de telefone do condômino pelo id da habitação

  ## Parameters

    `room_id`: String que representa o id da habitação
    `id_condominium`: String que representa o id do condomínio
  """
  def get_phone_number(room_id, id_condominium \\ 2) do
    "#{room_id}"
    |> by_room_id(id_condominium)
    |> Enum.map(fn e -> Map.get(e, "st_telefone_con") end)
  end

  @doc """
  Busca número de telefone e nome do condômino pelo id da habitação

  ## Parameters

    `room_id`: String que representa o id da habitação
    `keys`: Lista de Strings contendo os campos buscados
    `id_condominium`: String que representa o id do condomínio
  """
  def get_resident_profile(room_id, keys \\ @keys_resident_profile, id_condominium \\ 2) do
    case by_room_id(room_id, id_condominium) do
      [] ->
        {:error, "ID not found"}

      [resident | _] ->
        Enum.reduce(keys, %{}, fn key, map -> Map.put(map, key, Map.get(resident, key)) end)
    end
  end

  def profile_by_phone(phone) do
    find_anywhere(phone)
    |> handle_profile_by_phone()
  end

  defp handle_list_all({:ok, %HTTPoison.Response{status_code: 200, body: body}}) do
    body
    |> Jason.decode!()
    |> Enum.filter(fn %{"st_nometiporesp_tres" => type} -> type == "Residente" end)
  end

  defp handle_find_anywhere([nil, nil]), do: {:error, "resident not found"}
  defp handle_find_anywhere(values), do: Enum.into(values, [])

  defp handle_profile_by_phone({:error, "resident not found"}), do: {:error, "resident not found"}

  defp handle_profile_by_phone(profile) do
    profile =
      profile
      |> Enum.reject(fn item -> is_nil(item) end)
      |> hd()

    Enum.reduce(@keys_profile_by_phone, %{}, fn {key, header}, map ->
      Map.put(map, header, Map.get(profile, key))
    end)
  end
end
