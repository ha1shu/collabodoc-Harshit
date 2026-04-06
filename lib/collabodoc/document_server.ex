defmodule Collabodoc.DocumentServer do
  @moduledoc """
  A GenServer that owns the state of a single document.
  """
  use GenServer
  alias Collabodoc.OT

  # ── Public API ────────────────────────────────────────────────────────────

  def start_link(doc_id) do
    GenServer.start_link(__MODULE__, doc_id, name: via(doc_id))
  end

  def get_state(doc_id) do
    GenServer.call(via(doc_id), :get_state)
  end

  def submit_op(doc_id, client_id, client_revision, op) do
    GenServer.call(via(doc_id), {:submit_op, client_id, client_revision, op})
  end

  # ── GenServer Callbacks ───────────────────────────────────────────────────

  @impl true
  def init(_doc_id) do
    state = %{
      content: "",
      history: [],
      revision: 0
    }
    {:ok, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, {:ok, state.content, state.revision}, state}
  end

  @impl true
  def handle_call({:submit_op, client_id, client_revision, op}, _from, state) do
    concurrent_ops =
      state.history
      |> Enum.drop(client_revision)
      |> Enum.map(fn {o, _cid} -> o end)

    transformed_op = transform_against_all(op, concurrent_ops)

    case transformed_op do
      :noop ->
        {:reply, {:ok, :noop, state.revision}, state}

      op ->
        new_content = OT.apply_op(state.content, op)
        new_history = state.history ++ [{op, client_id}]
        new_revision = state.revision + 1

        new_state = %{state |
          content: new_content,
          history: new_history,
          revision: new_revision
        }

        {:reply, {:ok, op, new_revision}, new_state}
    end
  end

  # ── Private ───────────────────────────────────────────────────────────────

  defp transform_against_all(op, []), do: op
  defp transform_against_all(:noop, _), do: :noop
  defp transform_against_all(op, [concurrent | rest]) do
    transformed = OT.transform(op, concurrent)
    transform_against_all(transformed, rest)
  end

  defp via(doc_id) do
    {:via, Registry, {Collabodoc.DocumentRegistry, doc_id}}
  end
end
