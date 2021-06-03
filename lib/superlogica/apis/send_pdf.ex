defmodule Superlogica.Apis.SendPdf do
  use HTTPoison.Base
  require Logger
  alias Superlogica.Apis.AlertrackApi
  alias Superlogica.Helpers.Helpers
  alias Superlogica.Scheduler.QueueScheduler

  @endpoint "https://api.sac.digital/v2/client/notification/direct"
  @header_params ["number", "name", "type", "url"]
  @auth System.get_env("superlogica_token")
  @headers [
    {"Content-Type", "application/json"},
    {"Authorization", "Bearer #{@auth}"}
  ]

  @error_types [
    "invalid_type",
    "invalid_channel",
    "error_valid_wpp",
    "invalid_wpp",
    "invalid_param",
    "error_import"
  ]

  def process_url(url) do
    @endpoint <> url
  end

  def send_pdf(number, data, value \\ "") do
    Logger.info("#{__MODULE__}.send_pdf/2", ansi_color: :blue)

    body =
      Helpers.build_body(@header_params, [number, "Ed.", "file", data])
      |> Jason.encode!()

    AlertrackApi.send(number, data, @endpoint, body, @headers)
    |> retry_queue(number, data, value)
  end

  defp retry_queue(_content, _number, _message, %{"enqueued" => "enqueued"}),
    do: {:ok, "enqueued"}

  defp retry_queue({:ok, _content}, _number, _message, _value), do: {:ok, "success"}

  defp retry_queue({:error, %{"type" => error}}, number, message, _value) do
    Logger.info("#{__MODULE__}.retry_queue/3", ansi_color: :yellow)

    case error in @error_types do
      true ->
        %{"number" => number, "message" => message, "attempts" => 0}
        |> QueueScheduler.enqueue()

      false ->
        {:ok, "success"}
    end
  end

  defp retry_queue({:error, :timeout}, _number, _message, _value), do: {:error, :timeout}
end
