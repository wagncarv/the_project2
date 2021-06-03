defmodule Superlogica.Condominos.Reservations do
  @moduledoc """
    Módulo Responsável pela verificação das Áreas comuns, pelas Reservas e Informações de Reservas do condomínio.
  """
  require Logger
  alias Superlogica.Helpers.{Headers, Helpers, ChronoUnit}
  alias Superlogica.Condominium.Condominium

  @endpoint "https://api.superlogica.net/v2/condor/reservas/"

  @keys_do_reservation [
    "ID_CONDOMINIO_COND",
    "ID_UNIDADE_UNI",
    "ID_AREA_ARE",
    "DT_RESERVA_RES",
    "FL_NAO_NOTIFICAR_CONDOMINO",
    "FL_RESERVA_JA_CONFIRMADA",
    "VL_ADMVALORRESERVA_RES"
  ]

  @keys_handle_reservation [
    {"dt_reserva_res", "date"},
    {"id_area_are", "area_id"},
    {"id_condominio_cond", "condominium_id"},
    {"id_reserva_res", "reservation_id"},
    {"id_unidade_uni", "apartament_id"},
    {"vl_admvalorreserva_res", "price"}
  ]

  @keys_cancel_reservation [
    "ID_AREA_ARE",
    "ID_RESERVA_RES",
    "ID_CONDOMINIO_COND",
    "FL_NAO_NOTIFICAR_CONDOMINO",
    "ST_MOTIVOCANCELAMENTO_RES"
  ]

  @keys_reduce_reservation [
    {"fl_status_res", "status"},
    {"id_area_are", "area_id"},
    {"dt_reserva_res", "date"},
    {"id_condominio_cond", "condominium_id"},
    {"id_reserva_res", "reservation_id"},
    {"id_unidade_uni", "apartament_id"},
    {"st_bloco_uni", "block"},
    {"st_unidade_uni", "apartament"},
    {"vl_admvalorreserva_res", "price"},
    {"area_name", "area_name"},
    {"before_term", "minimum_reservation_days"},
    {"available_days", "maximum_reservation_days"}
  ]

  @headers Headers.headers()

  @common_areas [
    {"vl_valor_rec", "price"},
    {"id_area_are", "area_id"},
    {"st_nome_are", "area_name"},
    {"id_condominio_cond", "condominium_id"},
    {"nm_disponibilizardias_are", "max_availability_days"},
    {"nm_diasparareserva_are", "min_availability_days"}
  ]

  @doc """
    Função responsável pela apresentação de todas as áreas disponíveis por condominío.

    Para executar: Superlogica.Condominos.Reservations.common_areas(2)
    `Parâmetros:`

    - Id do condomínio: Número que representa o Condomínio no sistema da Superlógica.
  """
  def common_areas(condominium_id) do
    HTTPoison.get(@endpoint <> "areas?idCondominio=#{condominium_id}", @headers)
    |> handle_common_areas()
  end

  defp handle_common_areas({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
    Jason.decode(body)
    |> elem(1)
    |> Enum.map(fn e -> get_fields(e) end)
  end

  defp handle_common_areas({:ok, %HTTPoison.Response{body: body, status_code: 500}}) do
    %{"msg" => message} = Jason.decode!(body)
    {:error, reason: message}
  end

  defp get_fields(value, list \\ @common_areas) do
    Enum.reduce(list, %{}, fn {key, new_key}, map ->
      Map.put(map, new_key, Map.get(value, key))
    end)
  end

  def find_area_by_id(condominium_id, area_id) do
    common_areas(condominium_id)
    |> Enum.filter(fn %{"area_id" => id} -> id == "#{area_id}" end)
    |> List.first()
  end

  def available_dates(area_id, month, condominium_id \\ 2, status \\ "1") do
    (ChronoUnit.list_of_dates(month) -- reservation_dates(condominium_id, area_id, status))
    |> Enum.map(fn e -> Timex.format!(e, "{0D}/{0M}/{YYYY}") end)
  end

  def reservation_dates(condominium_id, area_id, status \\ "1") do
    reservation_by_area_id(condominium_id, area_id, status)
    |> Stream.map(fn e -> Map.get(e, "date") end) #//TODO mudar nomes das variáveis
    |> Stream.map(fn e -> String.replace(e, ~r/ 00:00:00/, "") end)
    |> Enum.map(fn e -> ChronoUnit.convert(e) end)
  end

  def reservation_by_area_id(condominium_id, area_id, status \\ "1") do
    case Condominium.by_id(condominium_id) do
      [] ->
        {:error, message: "Condominium does not exist"}

      _ ->
        HTTPoison.get(
          @endpoint <>
            "areasreservas?idCondominio=#{condominium_id}&idArea=#{area_id}&status=#{status}",
          Headers.headers()
        )
        |> handle_reservations_list()
    end
  end

  @doc """
  Função responsável por apresentar a lista de reservas feitas por condomínio.

  Para executar: Superlogica.Condominos.Reservations.reservations_list(2)
  `Parâmetros:`

  - Id do condomínio: Número que representa o Condomínio no sistema da Superlógica.
  """
  def reservations_list(condominium_id, status \\ "1") do
    case Condominium.by_id(condominium_id) do
      [] ->
        {:error, message: "Condominium does not exist"}

      _ ->
        HTTPoison.get(
          @endpoint <> "areasreservas?idCondominio=#{condominium_id}&idArea&status=#{status}",
          Headers.headers()
        )
        |> handle_reservations_list()
    end
  end

  defp handle_reservations_list({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
    values = body |> Jason.decode!()

    values
    |> Map.keys()
    |> Stream.filter(fn e -> Regex.match?(~r/[0-9]/, e) end)
    |> Stream.map(fn e -> Map.get(values, "#{e}") end)
    |> Enum.map(fn e -> Map.get(e, "areas_semelhantes") end)
    |> List.flatten()
    |> Enum.filter(fn %{"reservas" => reservation} -> reservation != [] end)
    |> include_area_name()
    |> Enum.map(fn e -> reduce_reservation_fields(e) end)
  end

  defp include_area_name(values) do
    values
    |> Enum.map(fn %{"reservas" => reservations, "st_nome_are" => area_name, "nm_disponibilizardias_are" => available_days , "nm_antecedencia_are" => before_term} ->
      {area_name, available_days, before_term, reservations}
    end)
    |> Enum.map(fn {name, available_days, before_term, map} ->
      Enum.map(map, fn element ->
        include_values(["area_name", "available_days", "before_term"], [name, available_days, before_term] , element)
      end)
    end)
    |> List.flatten()
  end

  defp include_values(keys, values, element) do
    Stream.zip(keys, values)
    |> Enum.map(fn {key, value} ->
      Map.put(element, key, value)
    end)
  end

  defp reduce_reservation_fields(map_value) do
    keys = Enum.map(@keys_reduce_reservation, fn {key, _value} -> key end)
    Enum.reduce(@keys_reduce_reservation, %{}, fn {key, new_key}, map ->
      if(key in keys, do: Map.put(map, new_key, Map.get(map_value, key)))
    end)
  end

  def by_apartment_id(apartment_id, condominium_id \\ 2, status \\ "1") do
    reservations_list(condominium_id, status)
    |> Enum.filter(fn e ->
      e["apartament_id"] == "#{apartment_id}"
    end)
  end

  @doc """
  Função responsável por fazer uma reserva.

  Para executar: Superlogica.Condominos.Reservations.do_reservation("2", "1", "11", "06/10/2021")
  `Parâmetros:`

  - Id do condomínio: Número que representa o Condomínio no sistema da Superlógica;
  - Id do Apartamento: Número que representa o Apartamento no sistema da Superlógica;
  - Id da Area: Número que representa a Área no sistema da Superlógica;
  - Data da reserva: Data escolhida para ser feita a reserva.
  """
  def do_reservation(condominium_id, apartment_id, area_id, reservation_date) do
    %{"price" => price} = find_area_by_id(condominium_id, area_id)

    body =
      Helpers.build_query_params(@keys_do_reservation, [
        condominium_id,
        apartment_id,
        area_id,
        reservation_date,
        "1",
        "1",
        price
      ])

    HTTPoison.post(@endpoint, body, Headers.header_urlencoded())
    |> handle_do_reservation
  end

  defp handle_do_reservation({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
    [%{"data" => data}] = Jason.decode!(body)

    Enum.reduce(@keys_handle_reservation, %{}, fn {key, new_key}, map ->
      Map.put(map, new_key, Map.get(data, key))
    end)
  end

  defp handle_do_reservation({:ok, %HTTPoison.Response{body: body, status_code: 206}}) do
    [%{"msg" => message}] = Jason.decode!(body)
    {:error, reason: message}
  end

  @doc """
  Função responsável por fazer o cancelamento de uma reserva

  Para executar: Superlogica.Condominos.Reservations.cancel_reservation("11", "6", "2")
  `Parametros:`

  - Id da Area: Número que representa a Área no sistema da Superlógica;
  - Id da Reserva: Número que representa a Reserva no sistema da Superlógica;
  - Id do Condominio: Número que representa o Condomínio no sistema da Superlógica;
  - Motivo do cancelamento: Motivo escolhido para ser feito o cancelamento da reserva.
  """
  def cancel_reservation(area_id, reservation_id, condominium_id, cancel_reason \\ "Evento cancelado") do
    body =
      Helpers.build_query_params(
        @keys_cancel_reservation,
        [area_id, reservation_id, condominium_id, "1", cancel_reason]
      )

    HTTPoison.put(@endpoint <> "cancelar", body, Headers.header_urlencoded())
    |> handle_cancel_reservation()
  end

  defp handle_cancel_reservation({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
    body |> Jason.decode()
  end

  defp handle_cancel_reservation({:ok, %HTTPoison.Response{body: body}})
       when is_bitstring(body) do
    case body =~ "Fatal error" do
      true -> {:error, "fatal error"}
      false -> {:error, "error"}
    end
  end
end
