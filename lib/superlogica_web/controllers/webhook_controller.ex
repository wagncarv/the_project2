defmodule SuperlogicaWeb.WebhookController do
  use SuperlogicaWeb, :controller
  alias Superlogica.Requests.Webhooks
  alias SuperlogicaWeb.FallbackController

  action_fallback FallbackController

  def receive(conn, %{"data" => data}) do
    [data["id_unidade_uni"], data["vl_total_recb"], data["dt_vencimento_recb"], "created"]
    |> Webhooks.optional_execute(data["link_segundavia"] |> String.replace(~r/-FaturaHtml/, ""))

    conn
    |> send_resp(:ok, %{status: 200} |> Jason.encode!())
  end

  def remove(conn, %{"data" => data}) do
    [data["id_unidade_uni"], data["vl_total_recb"], data["dt_vencimento_recb"], "deleted"]
    |> Webhooks.optional_execute(data["link_segundavia"] |> String.replace(~r/-FaturaHtml/, ""))

    conn
    |> send_resp(:ok, %{status: 200} |> Jason.encode!())
  end

  def update(conn, %{"data" => data}) do
    [data["id_unidade_uni"], data["vl_total_recb"], data["dt_vencimento_recb"], "changed"]
    |> Webhooks.optional_execute(data["link_segundavia"] |> String.replace(~r/-FaturaHtml/, ""))

    conn
    |> send_resp(:ok, %{status: 200} |> Jason.encode!())
  end
end
