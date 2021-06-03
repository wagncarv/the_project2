defmodule Superlogica.Apis.AlertrackApi do
  use HTTPoison.Base
  require Logger

  @endpoint "https://api.sac.digital/v2/client/notification/direct"
  @auth System.get_env("superlogica_token")

  @headers [
    {"Content-Type", "application/json"},
    {"Authorization", "Bearer #{@auth}"}
  ]

  def process_url(url) do
    @endpoint <> url
  end

  def send(_number, _message, url \\ @endpoint, body \\ %{}, headers \\ @headers) do
    Logger.info("#{__MODULE__}.send_message/6", ansi_color: :blue)

    HTTPoison.post(url, body, headers)
    |> handle_send()
  end

  defp handle_send({:ok, %HTTPoison.Response{body: body, status_code: 200}}) do
    {_, response} = body |> Jason.decode()

    case response["status"] do
      true -> {:ok, %{"message" => response["message"]}}
      false -> {:error, %{"type" => response["type"], "message" => response["message"]}}
    end
  end

  defp handle_send({:error, %HTTPoison.Error{id: nil, reason: :timeout}}),
    do: {:error, :timeout}

  defp handle_send({:ok, %HTTPoison.Response{status_code: 502}}),
    do: {:error, :bad_request}
end
