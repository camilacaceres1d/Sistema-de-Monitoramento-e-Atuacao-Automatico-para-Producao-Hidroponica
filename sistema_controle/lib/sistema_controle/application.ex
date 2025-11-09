defmodule SistemaControle.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SistemaControleWeb.Telemetry,
      SistemaControle.Repo,
      {DNSCluster, query: Application.get_env(:sistema_controle, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: SistemaControle.PubSub},
      # Start a worker by calling: SistemaControle.Worker.start_link(arg)
      # {SistemaControle.Worker, arg},
      # Start to serve requests, typically the last entry
      SistemaControleWeb.Endpoint,
      SistemaControle.MqttClient,
      {Oban, Application.fetch_env!(:sistema_controle, Oban)}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SistemaControle.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SistemaControleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
