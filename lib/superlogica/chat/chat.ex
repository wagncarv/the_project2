defmodule Superlogica.Chat.Chat do
  use GenServer
  require Logger
  alias Superlogica.Condominos.{Condominos, Expenses, Reservations}
  alias Superlogica.Helpers.{ChronoUnit, Helpers}
  alias Superlogica.Messages.{Messages}
  alias Superlogica.Random.RandomValues
  alias Superlogica.Condominium.LegalResponsibles, as: Responsibles
  alias Superlogica.Storage.Storage

  @fields ["number", "name", "protocol", "message"]
  @contact_updates ["available_dates", "area_id", "area_name", "chosen_area"]
  @message_patterns [~r/%RANDOM_QUESTION%/, ~r/%NAME%/, ~r/%FIRST_OPTION%/, ~r/%SECOND_OPTION%/, ~r/%THIRD_OPTION%/]

  def start_link(_ignored) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_no) do
    Logger.info("#{__MODULE__}.init/0 - New ETS table created", ansi_color: :blue)
    Storage.new_storage()
    {:ok, :ok}
  end

  # mensagens recebidas do controller
  def call(incoming) do
    Logger.info("#{__MODULE__}.call/1", ansi_color: :blue)

    #//TODO
    Storage.get(incoming["info"]["protocol"])
    |> reply(incoming)
  end

  # não há atendimento em andamento para este protocolo
  defp reply(return, values) when is_nil(return) do
    Logger.info("#{__MODULE__}.reply/1", ansi_color: :blue)

    values
    |> message_fields()
    |> greet_and_create()
  end

  # há atendimento em andamento para este protocolo
  defp reply(return, values) when is_tuple(return) do
    Logger.info("#{__MODULE__}.reply/1", ansi_color: :blue)

    %{"info" => %{"protocol" => protocol, "message" => message}} = values
    {key, contact, stage} = Storage.get(protocol)
    contact = Map.update!(contact, "message", fn _e -> message end)
    Storage.insert({key, contact, stage})

    listen_and_answer(contact, stage, stage["stage"])
  end

  # obter campos da mensagem
  defp message_fields(%{"contact" => contact, "info" => info}) do
    Logger.info("#{__MODULE__}.message_fields/1", ansi_color: :blue)
    message = Map.merge(contact, info)
    Enum.reduce(@fields, %{}, fn key, map -> Map.put(map, key, Map.get(message, key)) end)
  end

  # resposta ao primeiro contato
  # verifica se condômino existe
  # se não for condômino, encaminha para atendente
  # se for, continua chat
  defp greet_and_create(%{"protocol" => protocol, "number" => number} = contact) do
    Logger.info("#{__MODULE__}.greet_and_create/1", ansi_color: :blue)

    case Condominos.profile_by_phone(number) do
      {:error, "resident not found"} ->
        Storage.insert({protocol, contact, Messages.get_stage(201)})
        Logger.info(Messages.get_stage(4)["message"], ansi_color: :yellow)
        #//TODO
        # função API SAC para enviar mensagem WHATSAPP

      resident ->
        contact = Map.merge(contact, resident)
        contact = Map.put(contact, "for_validation", [String.slice(contact["cpf"], 8..10), contact["email"]])
        check_has_debts(contact)
        |> redirect(contact)
        #//
        #//TODO
        # função API SAC para envia mensagem WHATSAPP
    end
  end

  # cliente com dívida
  def redirect(true, contact) do
    Messages.get_stage(1)["message"]
    Storage.insert({contact["protocol"], contact, Messages.get_stage(2)})
    Logger.info(contact, label: "===ENVIANDO BOLETO===")
    Messages.get_stage(2)["message"]
  end

  # cliente sem dívida
  #//TODO
  def redirect(false, contact) do
    Logger.info("#{__MODULE__}.redirect/1")
    question = validation_question(contact)
    random_message = question["message"]["#{question["key"]}"]
    Messages.get_stage(1)["message"]
    |> Helpers.build_message([random_message, contact["name"]] ++ question["question"], @message_patterns)
    |> Logger.info(ansi_color: :green)
    Storage.insert({contact["protocol"], Map.put(contact, "key", question["key"] ), Messages.get_stage(102)})
    #//TODO PERGUNTA ALEATÓRIA
    # Messages.get_stage(6)
  end

  # função para verificar débitos
  def check_has_debts(contact) do
    Logger.info("#{__MODULE__}.check_has_debts/1", ansi_color: :blue)
    %{"apartment_id" => apartment_id, "condominium_id" => condominium_id} = contact
    Expenses.nonpayment(apartment_id, condominium_id)
    |> map_size > 0
  end

  # pergunta aleatória para validação
  def validation_question(contact) do
    Logger.info("#{__MODULE__}.validation_question/1", ansi_color: :blue)
    question = RandomValues.random_question(contact, 2)
    available_responses = question["#{question["key"]}"]
    |> Enum.shuffle()
    %{"question" => available_responses,"message" => question["message"], "key" => question["key"]}
  end

  # há atendimento em andamento para este protocolo
    #//TODO alterar encaminhamento. Ao chegar aqui, usuário deve já estar validado
  defp listen_and_answer(contact, stage, "2") do
    Logger.info("#{__MODULE__}.listen_and_answer/3, stage <<2>>", ansi_color: :blue)
    #//VERIFICAR ESTÁGIO
    cond do
      String.contains?(contact["message"], stage["positive_responses"]) ->
        Storage.insert({contact["protocol"], contact, Messages.get_stage(201)})
        Logger.info(Messages.get_stage(99)["message"], ansi_color: :yellow)
        String.contains?(contact["message"], stage["negative_responses"]) ->
          Storage.insert({contact["protocol"], contact, Messages.get_stage(101)})
          Logger.info(Messages.get_stage(101)["message"], ansi_color: :yellow)
      true ->
        Logger.info(Messages.get_stage(103), ansi_color: :yellow)
        Logger.info(Messages.get_stage(2), ansi_color: :yellow)
    end
  end

  # Menu principal
  defp listen_and_answer(contact, stage, "6") do
    Logger.info("#{__MODULE__}.listen_and_answer/3, stage <<6>>", ansi_color: :blue)
    cond do
        String.contains?(contact["message"], stage["financial_responses"]) ->
          Storage.insert({contact["protocol"], contact, Messages.get_stage(11)})
          Logger.info(Messages.get_stage(11)["menu"], ansi_color: :yellow)
          #//TODO CORRIGIR MAIS TARDE

        String.contains?(contact["message"], stage["info_responses"]) ->
          Logger.info(Messages.get_stage(35)["message"], ansi_color: :yellow)
          Logger.info(Responsibles.formatted_legal_responsibles(contact["condominium_id"]), ansi_color: :yellow)
          Storage.insert({contact["protocol"], contact, Messages.get_stage(35)})
          Logger.info(Messages.get_stage(105)["message"], ansi_color: :yellow)

        String.contains?(contact["message"], stage["ombudsman_responses"]) ->
          # FUNÇÃO QUE RETORNA OUVIDORIA
          Storage.insert({contact["protocol"], contact, Messages.get_stage(17)})
          Logger.info(Messages.get_stage(17)["message"], ansi_color: :yellow)

        # FUNÇÃO QUE RETORNA RESERVAS
        String.contains?(contact["message"], stage["reservation_responses"]) ->
        # FUNÇÃO QUE RETORNA RESERVAS
        # ================= FUNCIONANDO =======================================
          Storage.insert({contact["protocol"], contact, Messages.get_stage(18)})
          Logger.info(Messages.get_stage(18)["message"], ansi_color: :yellow)

        String.contains?(contact["message"], stage["finish_responses"]) ->
          Storage.insert({contact["protocol"], contact, Messages.get_stage(101)})
          Logger.info(Messages.get_stage(101)["message"], ansi_color: :yellow)
      true ->
        Logger.info(Messages.get_stage(103), ansi_color: :yellow)
        Storage.insert({contact["protocol"], contact, Messages.get_stage(6)})
        Logger.info(Messages.get_stage(6)["menu"], ansi_color: :yellow)
    end
  end

  # Menu financeiro
  defp listen_and_answer(contact, stage, "11") do
    Logger.info("#{__MODULE__}.listen_and_answer/3, stage <<11>>", ansi_color: :blue)
    #FUNÇÃO PARA SALVAR RECLAMAÇÃO, SUGESTÃO OU ELOGIO
      cond do
        String.contains?(contact["message"], stage["invoice_responses"]) ->
          check_expenses(contact) #//TODO
          Storage.insert({contact["protocol"], contact, Messages.get_stage(15)})
          Logger.info(Messages.get_stage(15)["message"], ansi_color: :yellow)
          #//TODO CORRIGIR MAIS TARDE

        String.contains?(contact["message"], stage["confirm_responses"]) ->
          # FUNÇÃO QUE RETORNA OUVIDORIA
          Storage.insert({contact["protocol"], contact, Messages.get_stage(201)})
          Messages.get_stage(99)["message"]
          |> String.replace(~r/%NAME%/, contact["name"])
          |> Logger.info(ansi_color: :yellow)

        String.contains?(contact["message"], stage["return_responses"]) ->
          Storage.insert({contact["protocol"],contact, Messages.get_stage(6)})
          Logger.info(Messages.get_stage(6)["menu"], ansi_color: :yellow)

          String.contains?(contact["message"], stage["talk_responses"]) ->
          Storage.insert({contact["protocol"], contact, Messages.get_stage(201)})
          Messages.get_stage(99)["message"]
          |> String.replace(~r/%NAME%/, contact["name"])
          |> Logger.info(ansi_color: :yellow)
            #//TODO CORRIGIR MAIS TARDE

          String.contains?(contact["message"], stage["finish_responses"]) ->
            Storage.insert({contact["protocol"], contact, Messages.get_stage(101)})
          Logger.info(Messages.get_stage(101)["message"], ansi_color: :yellow)
      true ->
        Logger.info(Messages.get_stage(103), ansi_color: :yellow)
        Logger.info(Messages.get_stage(104), ansi_color: :yellow)
    end
  end

  # Voltar ou sair
  defp listen_and_answer(contact, stage, "15") do
    Logger.info("#{__MODULE__}.listen_and_answer/3, stage <<15>>", ansi_color: :blue)

    cond do
      String.contains?(contact["message"], stage["return_responses"]) ->
        Storage.insert({contact["protocol"],contact, Messages.get_stage(11)})
        Logger.info(Messages.get_stage(6)["menu"], ansi_color: :yellow)
        #//TODO CORRIGIR MAIS TARDE

      String.contains?(contact["message"], stage["finish_responses"]) ->
        Storage.insert({contact["protocol"], contact, Messages.get_stage(101)})
        Logger.info(Messages.get_stage(101)["message"], ansi_color: :yellow)

    true ->
      Logger.info(Messages.get_stage(103)["message"], ansi_color: :yellow)
      Storage.insert({contact["protocol"],contact, Messages.get_stage(6)})
      Logger.info(Messages.get_stage(6)["menu"], ansi_color: :yellow)
  end

  end

  defp listen_and_answer(contact, stage, "16") do
    Logger.info("#{__MODULE__}.listen_and_answer/3, stage <<16>>", ansi_color: :blue)
    IO.inspect(contact, label: "16")
      cond do
        is_valid_option(contact["message"]) == false ->
          Logger.info(Messages.get_stage(103), ansi_color: :yellow)

        is_option_in_bounds(contact, String.trim(contact["message"])) == false ->
            Logger.info(Messages.get_stage(104), ansi_color: :yellow)

        true ->
          Storage.insert({contact["protocol"],contact, Messages.get_stage(19)})
      end
  end

  # Ouvidoria
  defp listen_and_answer(contact, stage, "17") do
    Logger.info("#{__MODULE__}.listen_and_answer/3, stage <<17>>", ansi_color: :blue)
    case String.contains?(contact["message"], stage["expected_responses"]) do
      true ->
        Storage.insert({contact["protocol"], contact, Messages.get_stage(6)})
        Messages.get_stage(106)
        Logger.info(Messages.get_stage(6)["menu"], ansi_color: :yellow)

      false -> nil
    end
  end

  # Menu, fazer reserva ou cancelar
  # 18 -> 16
  defp listen_and_answer(contact, stage, "18") do
    Logger.info("#{__MODULE__}.listen_and_answer/3, stage <<18>>", ansi_color: :blue)
    IO.inspect("18", label: "DEZOITO")
    cond do
        # RESERVAR
        String.contains?(contact["message"], stage["positive_responses"]) ->
          # ================= INÍCIO FUNCIONANDO ===============================
          # Logger.info(Messages.get_stage(21)["menu"], ansi_color: :yellow)
          # Logger.info(ChronoUnit.months_fullname(), ansi_color: :yellow)
          # Storage.insert({contact["protocol"], contact, Messages.get_stage(21)})
          # ================= FIM FUNCIONANDO ===============================

          # =================  TESTANDO ===============================
          areas = Reservations.common_areas(contact["condominium_id"])
          |> enumerate_areas()
          contact = Map.put(contact, "common_areas", areas)

          Storage.insert({contact["protocol"], contact, Messages.get_stage(16)})
          Logger.info(Messages.get_stage(16)["message"], ansi_color: :yellow)
          handle_area_message(areas)

        String.contains?(contact["message"], stage["negative_responses"]) ->
          Logger.info(Messages.get_stage(27)["message"], ansi_color: :yellow)
          info = reservation_info(contact["apartment_id"],contact["condominium_id"])
          contact = Map.put(contact, "reservation_info", info)
          Storage.insert({contact["protocol"], contact, Messages.get_stage(28)})
          Logger.info(format_reservation_message(contact["apartment_id"],contact["condominium_id"]), ansi_color: :yellow)
          Logger.info(Messages.get_stage(28)["message"], ansi_color: :yellow)

      true ->
        Logger.info(Messages.get_stage(103), ansi_color: :yellow)
        Storage.insert({contact["protocol"], contact, Messages.get_stage(6)})
        Logger.info(Messages.get_stage(6)["menu"], ansi_color: :yellow)
    end
  end

  defp listen_and_answer(contact, stage, "19") do
    Logger.info("#{__MODULE__}.listen_and_answer/3, stage <<19>>", ansi_color: :blue)

  end

  # VEIO DO 21
  defp listen_and_answer(contact, _stage, "20") do
    Logger.info("#{__MODULE__}.listen_and_answer/3, stage <<20>>", ansi_color: :blue)
    IO.inspect("21", label: "VINTE")
    message = contact["message"]
    |> String.downcase()
    |> String.trim()

    available_areas = area_by_option(message, contact)
    available_dates = available_areas
    |> elem(0)
    |> Reservations.available_dates(String.to_integer(Enum.at(contact["month_number"], 0)), contact["condominium_id"])
    |> IO.inspect(label: "DATAS DISPONÍVEIS ============= 20 =============") #//TODO
    contact = update_contact(contact, [available_dates, elem(available_areas, 0), elem(available_areas, 1), message])

    Logger.info(Messages.get_stage(34)["message"], ansi_color: :yellow)
    #//TODO TRATAR RESPOSTA ERRADA
    Storage.insert({contact["protocol"], contact, Messages.get_stage(22)})
  end

  # VERIFICA 20
  defp listen_and_answer(contact, _stage, "21") do
    Logger.info("#{__MODULE__}.listen_and_answer/3, stage <<21>>", ansi_color: :blue)
    IO.inspect("21", label: "VINTEUM")
    month_number = contact["message"]
    |> String.downcase()
    |> find_month_number()
    |> handle_find_month_number()

    case month_number do
      false ->
        Messages.get_stage(31)["message"]

        _ ->
        areas = Reservations.common_areas(contact["condominium_id"])
        |> enumerate_areas()
        contact = Map.put(contact, "month_number", month_number)
        |> Map.put("common_areas", areas)

        Storage.insert({contact["protocol"], contact, Messages.get_stage(20)})
        Logger.info(Messages.get_stage(20)["message"], ansi_color: :yellow)
        handle_area_message(areas)
    end
  end

  defp listen_and_answer(contact, _stage, "22") do
    Logger.info("#{__MODULE__}.listen_and_answer/3, stage <<22>>", ansi_color: :blue)
    IO.inspect("22", label: "VINTEDOIS")
    reservation_month = List.first(contact["month_number"])
    |> String.pad_leading(2, "0")

    date = contact["available_dates"]
    |> find_chosen_date(ChronoUnit.simple_naive_format(String.trim(contact["message"]), reservation_month))

    case date do
      0 ->
        Logger.info(Messages.get_stage(33)["message"], ansi_color: :yellow)

      chosen_day ->
        Logger.info(Messages.get_stage(37)["message"]
        |> Helpers.build_message([contact["chosen_area"], chosen_day], [~r/%OPTION%/, ~r/%DAY%/]), ansi_color: :yellow)
        Storage.insert({contact["protocol"], Map.put(contact, "chosen_day", chosen_day), Messages.get_stage(38)})
    end
  end

  # RESERVAS
  # //TODO
  defp listen_and_answer(contact, stage, "28") do
    Logger.info("#{__MODULE__}.listen_and_answer/3, stage <<28>>", ansi_color: :blue)
    count = to_string(Enum.count(contact["reservation_info"]))
    cond do
        String.contains?(contact["message"], stage["finish_responses"]) ->
          Storage.insert({contact["protocol"], contact, Messages.get_stage(101)})
          Logger.info(Messages.get_stage(101)["message"], ansi_color: :yellow)
          #//TODO CORRIGIR MAIS TARDE

        String.contains?(contact["message"], stage["return_responses"]) ->
          Storage.insert({contact["protocol"], contact, Messages.get_stage(6)})
          Logger.info(Messages.get_stage(6)["menu"], ansi_color: :yellow)

        String.contains?(contact["message"], stage["cancel_responses"]) ->
          cancel_all_reservations(contact["apartment_id"], contact["condominium_id"])
          Logger.info(Messages.get_stage(30)["message"], ansi_color: :yellow)
          Storage.insert({contact["protocol"], contact, Messages.get_stage(15)})
          Logger.info(Messages.get_stage(15)["message"], ansi_color: :yellow)

          String.match?(contact["message"], ~r/[0-9]/) == true ->
            # //TODO TRANSFORMAR EM FUNÇÃO
          if String.to_integer(contact["message"]) <= String.to_integer(count) do
            %{"area_id" => area_id, "reservation_id" => reservation_id} =
              Enum.find(contact["reservation_info"], fn %{"option" => option} ->
              to_string(option) == contact["message"]
            end)

            Reservations.cancel_reservation(area_id, reservation_id, contact["consominium_id"])
            Messages.get_stage(30)["message"]
            Storage.insert({contact["protocol"], contact, Messages.get_stage(15)})
            Logger.info(Messages.get_stage(15)["message"], ansi_color: :yellow)

          else
            Messages.get_stage(29)["message"]
            |> String.replace("%OPTION%", count)
          end

        true ->
          Messages.get_stage(29)["message"]
          |> String.replace("%OPTION%", count)
    end
  end

   #//TODO 35 INFORMAÇÕES
  defp listen_and_answer(contact, stage, "35") do
    Logger.info("#{__MODULE__}.listen_and_answer/3, stage <<35>>", ansi_color: :blue)
    message = String.trim(contact["message"])
    cond do
      String.contains?(message, stage["return_responses"]) ->
        Storage.insert({contact["protocol"],contact, Messages.get_stage(6)})
        Logger.info(Messages.get_stage(6)["menu"], ansi_color: :yellow)

      String.contains?(message, stage["finish_responses"]) ->
        Storage.insert({contact["protocol"],contact, Messages.get_stage(101)})
        Logger.info(Messages.get_stage(101)["message"], ansi_color: :yellow)

      true ->
        Logger.info(Messages.get_stage(103)["message"], ansi_color: :yellow)
    end
  end

  # FAZER RESERVA
  # //TODO ========================================================================================
  defp listen_and_answer(contact, stage, "38") do
    Logger.info("#{__MODULE__}.listen_and_answer/3, stage <<38>>", ansi_color: :blue)
     cond do
        String.contains?(contact["message"], stage["confirmation_responses"]) ->
        Reservations.do_reservation(
          contact["condominium_id"], contact["apartment_id"], contact["area_id"], ChronoUnit.simple_naive_format(contact["chosen_day"])
        )
        |> reservation_information(contact)
        |> Logger.info(ansi_color: :yellow)

        Storage.insert({contact["protocol"],contact, Messages.get_stage(105)})
        Logger.info(Messages.get_stage(105)["message"], ansi_color: :yellow)

        String.contains?(contact["message"], stage["decline_responses"]) ->
        Logger.info(Messages.get_stage(105)["message"], ansi_color: :yellow)
        Storage.insert({contact["protocol"],contact, Messages.get_stage(105)})

      true ->
        Logger.info(Messages.get_stage(103)["message"], ansi_color: :yellow)
        Logger.info(Messages.get_stage(104)["message"], ansi_color: :yellow)
    end
  end

  defp listen_and_answer(_contact, _stage, "101") do
    Logger.info("#{__MODULE__}.listen_and_answer/3, stage <<101>>", ansi_color: :blue)
    #FUNÇÃO PARA SALVAR RECLAMAÇÃO, SUGESTÃO OU ELOGIO
    # save_ombudsman(contact["message"])
    Logger.info(Messages.get_stage(101)["message"], ansi_color: :yellow)
  end

  # Validar usuário
  defp listen_and_answer(contact, _stage, "102") do
    Logger.info("#{__MODULE__}.listen_and_answer/3, stage <<102>>", ansi_color: :blue)
    case contact["message"] in contact["for_validation"] do
      false ->
        Storage.insert({contact["protocol"],contact, Messages.get_stage(101)})
        Logger.info(Messages.get_stage(36)["message"], ansi_color: :yellow)
        Logger.info(Responsibles.formatted_by_occupation(contact["condominium_id"]), ansi_color: :yellow)
      true ->
        Storage.insert({contact["protocol"],contact, Messages.get_stage(6)})
        Logger.info(Messages.get_stage(6)["menu"], ansi_color: :yellow)
    end
  end

  # Retornar ou sair
  defp listen_and_answer(contact, stage, "105") do
    Logger.info("#{__MODULE__}.listen_and_answer/3, stage <<105>>", ansi_color: :blue)
    cond do
      String.contains?(contact["message"], stage["positive_responses"]) ->
        Logger.info(Messages.get_stage(6)["menu"], ansi_color: :yellow)
        Storage.insert({contact["protocol"],contact, Messages.get_stage(6)})

      String.contains?(contact["message"], stage["negative_responses"]) ->
        Logger.info(Messages.get_stage(101)["message"], ansi_color: :yellow)
        Storage.insert({contact["protocol"],contact, Messages.get_stage(101)})
      true ->
        Logger.info(Messages.get_stage(103)["message"], ansi_color: :yellow)
        Logger.info(Messages.get_stage(104)["message"], ansi_color: :yellow)
    end
  end

  defp listen_and_answer(contact, _stage, "107") do
    Logger.info("#{__MODULE__}.listen_and_answer/3, stage <<107>>", ansi_color: :blue)

    Storage.insert({contact["protocol"], contact, Messages.get_stage(107)})
    Messages.get_stage(107)
  end

  defp listen_and_answer(_contact, _stage, "201") do
    Logger.info("#{__MODULE__}.listen_and_answer/3, stage <<201>>", ansi_color: :blue)
    Logger.info( Messages.get_stage(201)["message"], ansi_color: :yellow)
  end

  def check_expenses(%{"apartment_id" => apartment_id, "condominium_id" => condominium_id}) do
    debts = Expenses.list_expenses(apartment_id, "01/01/#{Date.utc_today.year}", ChronoUnit.format_today_to_custom, condominium_id)
    case debts do
      [] ->
        IO.inspect Messages.get_stage(26)
      [%{"dt_vencimento_recb" => expiry, "vl_total_recb" => debt}] -> IO.puts "Vencimento = #{expiry} - Débito = R$#{debt}"
    end
  end

  # formatar mensagem de reservas
  def format_reservation_message(apartment_id, condominium_id \\ 2, status \\ 1) do
    reservations = Reservations.by_apartment_id(apartment_id, condominium_id, status)
    Enum.map(1..Enum.count(reservations), fn element ->
      Enum.reduce(reservations, "", fn %{"area_name" => area, "date" => date}, str ->
        [area, shift] = String.split(area, " - ")
        "#{str}*#{element}* Área reservada: #{area}\nData: #{ChronoUnit.naive_format(date)}\nTurno: #{shift} "
      end)
    end)
    |> Enum.join("\n\n")
  end

  defp reservation_info(apartment_id, condominium_id, status \\ 1) do
    reservations = Reservations.by_apartment_id(apartment_id, condominium_id, status)
    Enum.map(1..Enum.count(reservations), fn e -> e end)
    |> Enum.zip(reservations)
    |> Enum.map(fn {number, %{"apartament_id" => apartment_id, "area_id" => area_id, "area_name" => area_name, "reservation_id" => reservation_id}} ->
      %{"option" => number, "apartment_id" => apartment_id, "reservation_id" => reservation_id, "area_id" => area_id, "area_name" => area_name}
    end)
  end

  # CENCELAR TODAS RESERVAS
  defp cancel_all_reservations(apartment_id, condominium_id, status \\ 1) do
    reservation_info(apartment_id,condominium_id, status)
    |> Enum.map(fn %{"area_id" => area_id,"reservation_id" => reservation_id} ->
      Reservations.cancel_reservation(area_id, reservation_id, condominium_id, "Evento cancelado")
    end)
  end

  defp find_month_number(value) do
    ChronoUnit.months_fullname
    |> String.downcase()
    |> String.split("\n")
    |> Enum.filter(fn e -> Regex.match?(~r/#{value}/, e) end)
  end

  defp handle_find_month_number(value) when value == [], do: false
  defp handle_find_month_number(value), do: value |> hd() |> String.split(" - ")

  defp handle_area_message(value) do
    Enum.map(1..Enum.count(value), fn e -> e end)
    |> Enum.zip(value)
    |> Enum.reduce("", fn {number, %{"area_name" => area}}, str ->
      "#{str}#{number} - #{area}\n"
    end)
  end

  defp enumerate_areas(value) do
    Enum.map(1..Enum.count(value), fn e -> e end)
    |> Enum.zip(value)
    |> Enum.map(fn {number, map} -> Map.put(map, "area_option_number", number) end)
  end

  defp area_by_option(choice, contact) do
    %{"area_id" => area_id, "area_name" => area_name} = contact["common_areas"]
    |> Enum.find(fn %{"area_option_number" => option} ->
      option == String.to_integer(choice) end)
    {area_id, area_name}
  end

  defp find_chosen_date(dates, _message) when is_nil(dates), do: 0
  defp find_chosen_date(dates, _message) when dates == [], do: 0
  defp find_chosen_date(dates, message) do
    message = message
    |> String.trim()
    |> String.pad_leading(10, "0")
    Enum.find(dates,0, fn e ->
      e == message
    end)
  end

  defp update_contact(contact, values_list) do
    Stream.zip(@contact_updates, values_list)
    |> Enum.reduce(contact, fn {key, value}, contact ->
      Map.put(contact, key, value)
    end)
  end

  defp reservation_information(reservation, contact) do
    %{"date" => date, "reservation_id" => reservation_id} = reservation
    "Dados da reserva:\nData: #{ChronoUnit.naive_format(date)}\nÁrea reservada: #{contact["area_name"]}\nNúmero da reserva: #{reservation_id}"
  end

  # Verifica se argumento é um número
  defp is_valid_option(option) do
    option
    |> String.trim()
    |> String.match?(~r/[0-9]{1,}/)
  end

  # Verificar se opção existe
  defp is_option_in_bounds(%{"comom_areas" => common_areas}, option) do
    count_areas = Enum.map(1..Enum.count(common_areas), fn e -> e end)
    option in count_areas
  end
end
