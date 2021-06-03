defmodule Superlogica.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      # Superlogica.Repo,
      # Start the Telemetry supervisor
      SuperlogicaWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Superlogica.PubSub},
      # Start the Endpoint (http/https)
      SuperlogicaWeb.Endpoint,
      # Start a worker by calling: Superlogica.Worker.start_link(arg)
      # {Superlogica.Worker, arg}
      {Superlogica.Chat.Chat, [:init]},
      Superlogica.Scheduler.QueueScheduler
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Superlogica.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    SuperlogicaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
