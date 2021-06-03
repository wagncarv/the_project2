defmodule Superlogica.Scheduler.QueueScheduler do
  use GenServer
  require Logger
  alias Superlogica.Apis.SendMessage
  alias Superlogica.Apis.SendPdf

  @max_attempts 5

  def start_link(_state) do
    Logger.info("#{__MODULE__}.start_link/", label: "GenServer started ...")
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  # SERVER
  @impl true
  def init(state \\ %{}) do
    schedule_notification()
    {:ok, state}
  end

  @impl true
  def handle_info(:generate, state) do
    Logger.info("#{__MODULE__}.handle_info/2")
    notify()
    schedule_notification()
    resend()
    {:noreply, state}
  end

  @impl true
  def handle_cast({:enqueue, value}, state) do
    Logger.info("#{__MODULE__}.handle_cast/2, :enqueue")
    new_state = put_new?(value, state)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:dequeue, number}, state) do
    Logger.info("#{__MODULE__}.handle_cast/2")
    new_state = Enum.reject(state, fn e -> e["number"] == number end)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:notify, state) do
    Logger.info("#{__MODULE__}.handle_cast/2")
    keep_or_remove()
    {:noreply, state}
  end

  @impl true
  def handle_cast(:keep_or_remove, state) do
    Logger.info("#{__MODULE__}.handle_cast/2")
    update_keys()
    Enum.each(state, fn e -> remove(e) end)
    {:noreply, state}
  end

  @impl true
  def handle_cast(:update_keys, state) do
    Logger.info("#{__MODULE__}.handle_cast/2")
    new_state = Enum.map(state, fn e -> Map.put(e, "attempts", e["attempts"] + 1) end)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:resend, state) do
    Logger.info("#{__MODULE__}.handle_cast/2")

    unless(Enum.empty?(state),
      do:
        Enum.map(state, fn e ->
          with {:ok, _} <- SendMessage.send_message(e["number"], e["message"], e),
               {:ok, _} <- SendPdf.send_pdf(e["number"], e["message"], e) do
            dequeue(e["number"])
          else
            {:error, _} -> {:error, "The message was not sent"}
          end
        end)
    )

    {:noreply, state}
  end

  defp schedule_notification do
    Logger.info("#{__MODULE__}.schedule_notification/0")
    Process.send_after(self(), :generate, 1000 * 60 * 60)
  end

  #
  def enqueue(element) do
    Logger.info("#{__MODULE__}.enqueue/1")
    GenServer.cast(__MODULE__, {:enqueue, element})
  end

  def dequeue(number) do
    Logger.info("#{__MODULE__}.dequeue/1")
    GenServer.cast(__MODULE__, {:dequeue, "#{number}"})
  end

  defp notify do
    Logger.info("#{__MODULE__}.notify/0")
    GenServer.cast(__MODULE__, :notify)
  end

  def keep_or_remove do
    Logger.info("#{__MODULE__}.keep_or_remove/0")
    GenServer.cast(__MODULE__, :keep_or_remove)
  end

  defp remove(%{"attempts" => attempts, "number" => number}) when attempts >= @max_attempts do
    Logger.info("#{__MODULE__}.remove/0", ansi_color: :yellow)
    dequeue(number)
  end

  defp remove(_), do: {:ok, "success"}

  defp resend do
    Logger.info("#{__MODULE__}.resend/0")
    GenServer.cast(__MODULE__, :resend)
  end

  defp put_new?(value, list) do
    case Map.has_key?(value, "enqueued") do
      true -> list
      false -> List.insert_at(list, 0, Map.put(value, "enqueued", "enqueued"))
    end
  end

  def update_keys do
    Logger.info("#{__MODULE__}.update_keys/0")
    GenServer.cast(__MODULE__, :update_keys)
  end
end
