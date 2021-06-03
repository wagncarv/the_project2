defmodule Superlogica.Apis.SendSms do
  use HTTPoison.Base
  require Logger
  alias Superlogica.Apis.AlertrackApi
  alias Superlogica.Helpers.Helpers

  @endpoint "https://api.sac.digital/v2/client/sms/direct"
  @body_params ["number", "name", "type", "text"]

  def process_url(url) do
    @endpoint <> url
  end

  def send_sms(number, message) do
    Logger.info("#{__MODULE__}.notify_sms/2", ansi_color: :blue)

    body =
      Helpers.build_body(@body_params, [number, "Ed.", "text", message])
      |> Jason.encode!()

    AlertrackApi.send(number, message, @endpoint, body)
  end
end
