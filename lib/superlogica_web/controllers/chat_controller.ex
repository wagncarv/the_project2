defmodule SuperlogicaWeb.ChatController do
  use SuperlogicaWeb, :controller
  alias Superlogica.Chat.Chat

  def chat(conn, values) do
    Chat.call(values)

    conn
    |> send_resp(:ok, %{status: 200} |> Jason.encode!())
  end
end
