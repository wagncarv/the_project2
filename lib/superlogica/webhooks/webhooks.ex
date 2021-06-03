defmodule Superlogica.Requests.Webhooks do
  require Logger
  alias Superlogica.Helpers.{ChronoUnit, Headers, Helpers}
  alias Superlogica.Messages.ParseFile
  alias Superlogica.Apis.SendMessage
  alias Superlogica.Apis.SendPdf
  alias Superlogica.Condominos.Condominos

  # rota principal
  @url_webhook "https://api.superlogica.net/v2/condor/webhooks/"

  # cabeçalho com parâmetros obrigatórios
  @headers Headers.headers()

  # parâmetros para registrar webhook
  @keys_register ["nome", "url", "email", "naoValidarUrl", "id_app"]

  @message_patterns [~r/%SAUDACAO%/, ~r/%NAME%/, ~r/%VALUE%/, ~r/%EXPIRE%/]

  # registra webhook na plataforma Superlógica
  def register_webhook(webhook_name, url, email) do
    Logger.info("#{__MODULE__}.register_webhook/3", ansi_color: :blue)
    body = build_body(@keys_register, [webhook_name, url, email, 1, 85])

    build_register_params(webhook_name, url, email)
    |> send_post(body)
    |> handle_register_webhook()
  end

  # remove webhook
  def delete_webhook(id) do
    Logger.info("#{__MODULE__}.delete_webhook/1", ansi_color: :blue)

    "#{@url_webhook}delete?#{
      Helpers.build_query_params(["ID_WEBHOOK_WHK", "ID_APP_APP"], [id, 85])
    }"
    |> HTTPoison.delete(@headers)
    |> handle_delete_webhook()
  end

  # lista webhooks cadastrados
  def list_webhooks do
    Logger.info("#{__MODULE__}.webhooks_list/0", ansi_color: :blue)

    HTTPoison.get("#{@url_webhook}index", @headers)
    |> handle_list_webhooks()
  end

  # recebe lista de chaves e valores, retorna-os em formato JSON
  defp build_body(keys_list, params_list) do
    Logger.info("#{__MODULE__}.build_body/2", ansi_color: :blue)

    Helpers.build_body(keys_list, params_list)
    |> Jason.encode!()
  end

  # parâmetros para criar webhook
  def build_register_params(name, url, email) do
    Logger.info("#{__MODULE__}.build_register_params/3", ansi_color: :blue)

    "#{@url_webhook}put?#{Helpers.build_query_params(@keys_register, [name, url, email, 1, 85])}"
  end

  # requisição post
  defp send_post(url, body) do
    Logger.info("#{__MODULE__}.send_post/2", ansi_color: :blue)
    HTTPoison.post(url, body, @headers)
  end

  defp handle_register_webhook({:ok, %HTTPoison.Response{status_code: 206, body: body}}) do
    [%{"msg" => msg}] = body |> Jason.decode!()
    {:error, msg}
  end

  defp handle_register_webhook({:ok, %HTTPoison.Response{status_code: 200, body: body}}) do
    [%{"status" => _status, "msg" => msg}] = body |> Jason.decode!()
    {:ok, msg}
  end

  defp handle_register_webhook({:error, %HTTPoison.Error{id: nil, reason: :timeout}}),
    do: {:error, :timeout}

  defp handle_delete_webhook({:ok, %HTTPoison.Response{body: body}}) do
    case body =~ "Fatal error" do
      true ->
        {:error, "Invalid ID"}

      _ ->
        [%{"msg" => msg, "status" => status}] =
          body
          |> Jason.decode!()

        {status, msg}
    end
  end

  defp handle_list_webhooks({:ok, %HTTPoison.Response{body: body}}) do
    body
    |> Jason.decode!()
    |> list_item()
  end

  defp list_item(items) do
    Logger.info("#{__MODULE__}.list_items/1", ansi_color: :blue)

    items
    |> Enum.map(fn item ->
      %{
        "id" => item["id_webhook_whk"],
        "license" => item["st_licenca_whk"],
        "name" => item["st_nome_whk"],
        "url" => item["st_url_whk"]
      }
    end)
  end

  def webhook_event_message(name, value, expire \\ "", opt \\ "created") do
    Logger.info("#{__MODULE__}.webhook_event_message/4", ansi_color: :blue)

    ParseFile.build("webhooks_messages.json")["bill_#{opt}"]["message"]
    |> Helpers.build_message([ChronoUnit.greeting(), name, value, expire], @message_patterns)
  end

  def optional_execute(fields, url \\ "") do
    Logger.info("#{__MODULE__}.optional_execute/1", ansi_color: :blue)
    [room_id, value, expire, opt] = fields
    values = Condominos.get_resident_profile(room_id)

    if values != {:error, "ID not found"} do
      message = webhook_event_message(values["st_nome_con"], value, expire, opt)
      SendMessage.send_message(values["st_telefone_con"], message)
      SendPdf.send_pdf(values["st_telefone_con"], url)
    end
  end
end
