defmodule Collabodoc.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
  CollabodocWeb.Telemetry,
  {DNSCluster, query: Application.get_env(:collabodoc, :dns_cluster_query) || :ignore},
  {Registry, keys: :unique, name: Collabodoc.DocumentRegistry},
  {DynamicSupervisor, name: Collabodoc.DocumentSupervisor, strategy: :one_for_one},
  {Phoenix.PubSub, name: Collabodoc.PubSub},
  CollabodocWeb.Endpoint
]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Collabodoc.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CollabodocWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
