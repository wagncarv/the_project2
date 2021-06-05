defmodule Teste do
  require Logger
  alias Superlogica.Storage.Storage
  alias Superlogica.Helpers.Helpers
  alias Superlogica.Messages.ParseFile
  # alias Superlogica.Elastic.Elastic
  alias Superlogica.Requests.Webhooks
  # alias Superlogica.Helpers.Helpers
  # alias Superlogica.Condominos.Condominos
  alias Superlogica.Apis.SendMessage
  alias Superlogica.Apis.SendPdf
  alias Superlogica.Apis.SendSms
  # alias Superlogica.Elastic.Elastic
  alias Superlogica.Env.Env
  alias Superlogica.Helpers.ChronoUnit
  # alias Superlogica.Condominos.Reservations
  # use Timex
  # use GenServer
  alias Superlogica.Messages.Messages
  alias Superlogica.Chat.Chat
  alias Superlogica.Condominos.Expenses
  alias Superlogica.Condominos.Condominos
  alias Superlogica.Scheduler.QueueScheduler
  alias Superlogica.Helpers.Headers
  alias Superlogica.Condominium.Condominium
  alias Superlogica.Random.RandomValues
  alias Superlogica.Condominos.Reservations
  alias Superlogica.Condominium.LegalResponsibles
  use Timex

  # Teste2.teste("abc", "14425801008")
  def teste do

    dispo = ["19-07-2021", "01-12-2021",
    "05/06/2021", "06/06/2021", "07/06/2021", "08/06/2021", "09/06/2021"]

    feitas = ["19-07-2021", "01-12-2021",
    "01-12-2021", "03-12-2021", "03-12-2021", "03-12-2021", "23-12-2021"]

    dispo -- feitas


    # Reservations.reservation_by_area_id(2, 13)
    # Reservations.common_areas(2)
    # Reservations.reservation_dates(2, 13)
    # |> Stream.map(fn e -> DateTime.to_date(e) end)
    # |> Stream.map(fn e -> Timex.format(e, "{0D}-{0M}-{YYYY}") end)
    # |> Enum.map(fn {_, date} -> date end)

  end
end
