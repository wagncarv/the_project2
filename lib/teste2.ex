defmodule Teste2 do
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
  alias Superlogica.Random.RandomQuestions
  use Timex


##### 55279985217892
##### 552754565432
##### santosrom@mail.com
#### 14425801008


# Teste2.teste("abc", "14425801008")
# Teste2.teste("abc", "")
# Timex.format(date, "{0D}-{0M}-{YYYY}")
# {:ok, "2016-02-29"}
  def teste(protocol, msg) do

    %{
      "manager_id" => 4,
      "channel" => %{
         "id" => "36",
         "id_api" => "3M",
         "number" => "5527988140835",
         "name" => "Cocada Bot"
      },
      "contact" => %{
         "id" => "13086",
         "id_api" => "9D5B",
         "number" => "552754565432",
         "name" => "Su@bot T\u00e9cnico"
      },
      "info" => %{
         "protocol" => "#{protocol}",
         "type" => "text",
         "message" => "#{msg}",
         "hash" => "3EB0D41F0C30662CDF9D"
      },
      "config" => %{
         "sac_token" => "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9.eyJhdWQiOiI5MzUyMzZiNS00N2FhLTQ0MWYtYTEyNS0yODk2OTQyMGE1Y2IiLCJqdGkiOiI5ZDQwMjk1NjVhNjBmNTcyNDQyMjQ4ZjgxNTE1YjkxMTBiMDRiYjM1YTIwNmFkN2Y1ZjIxNDVjZTAzOWRlMDkyYTNhMGU4NTE1ZmNhNmJlOCIsImlhdCI6MTYxOTgxMzI4NSwibmJmIjoxNjE5ODEzMjg1LCJleHAiOjE2MjA0MTgwODUsInN1YiI6IjEiLCJzY29wZXMiOlsibWFuYWdlciJdfQ.DZ6tRYW6g8xYNCsyZCbTnN7XZ0Ka2DxRY8rUfmXdPsTDVxPngFEhO6Z9Ix-aM40amRpxz9_JCSdbQqPOudfhKXCRzILaxUCGPhZeiWCzHEI1iBf_gMbsAgN2XDEgZsjOrPMQiIJGfdzR3DWd3oJP5ALWrN9UQqIGEdrUuZQ1qXfvOXQ5K4DfD4hPgoceiBrr7YL1ga19e4lS07052X_6qRKfRwdxui7ASdqv0evgT-u14VbLbOO26vooCymFW7mOS5D7kxiI_rCjTW4wDdUFmNmp6iVI3CWJ1KR__alzPE2vU2RN-6guTaDp0j1YX147ufuU2rvMwk0F4g4FLH9l4qsiFhT_RC2V1w2BSW1L115V1hWqymJjKbu0rVGajY-bObvgN6eXCp6HkwFEpdO05pW2vJTJpwrwL9k6HMy2i4UxHHgJP5UI2TWNzLtjbQOcu_3r2coBHQ-6sVOm-530ES6lrnqN5INJ8Eld8LQ4zIJ5Lh7P1XH9D1h8r3xLLDsjK3iOCIP3_Yg5yzkGMyFqlWpZ_6rL_TvScWV-Nw9B1h3z6-hPoHCMyQcv84cgSalWVpZd88BfWjO0RTciQLVgzKnOBT-J8tcCFoSaEIAo1kqGxZKBrqUanOv9wUxMNXH6nHxRi4EiGa8zQUSPMbXf_ws1tf7b0YKpyiUtMRDBNS8",
         "superlogica_app_token" => "8ab8d652-d78a-388d-9b59-4e53463ba870",
         "superlogica_access_token" => "a2c69f6b-1a44-3379-8a77-a39033a753f1"
      }
   } |>
    Chat.call()

  end
end
