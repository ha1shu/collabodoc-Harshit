defmodule Collabodoc.DocumentManager do
  @moduledoc "Starts and finds document server processes."

  def get_or_start(doc_id) do
    case DynamicSupervisor.start_child(
      Collabodoc.DocumentSupervisor,
      {Collabodoc.DocumentServer, doc_id}
    ) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
      error -> error
    end
  end
end
