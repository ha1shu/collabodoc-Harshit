defmodule CollabodocWeb.ChannelCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Phoenix.ChannelTest
      import CollabodocWeb.ChannelCase

      @endpoint CollabodocWeb.Endpoint
    end
  end

  setup _tags do
    # Start Registry if not already running
    case Registry.start_link(keys: :unique, name: Collabodoc.DocumentRegistry) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end

    # Start DynamicSupervisor if not already running
    case DynamicSupervisor.start_link(name: Collabodoc.DocumentSupervisor, strategy: :one_for_one) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end

    :ok
  end
end
