defmodule SuperlogicaWeb.FallbackController do
  use SuperlogicaWeb, :controller

  def call(conn, {:error, %{result: _result, status: status}}) do
    conn
    |> put_status(status)
    |> send_resp(:error, %{status: status} |> Jason.encode!())
  end

  def call(conn, {:error, _message}) do
    conn
    |> put_status(:bad_request)
    |> send_resp(:error, %{status: 404} |> Jason.encode!())
  end
end
