defmodule CollabodocWeb.DocumentChannel do
  use Phoenix.Channel
  alias Collabodoc.{DocumentManager, DocumentServer}

  def join("doc:" <> doc_id, params, socket) do
    client_id = Map.get(params, "client_id", generate_client_id())

    :ok = DocumentManager.get_or_start(doc_id)

    {:ok, content, revision} = DocumentServer.get_state(doc_id)

    socket =
      socket
      |> assign(:doc_id, doc_id)
      |> assign(:client_id, client_id)

    {:ok, %{content: content, revision: revision}, socket}
  end

  def handle_in("op", %{"revision" => client_revision, "op" => raw_op}, socket) do
    doc_id = socket.assigns.doc_id
    client_id = socket.assigns.client_id

    op = decode_op(raw_op)

    case DocumentServer.submit_op(doc_id, client_id, client_revision, op) do
      {:ok, :noop, revision} ->
        {:reply, {:ok, %{revision: revision}}, socket}

      {:ok, transformed_op, revision} ->
        broadcast_from!(socket, "op", %{
          op: encode_op(transformed_op),
          revision: revision,
          client_id: client_id
        })

        {:reply, {:ok, %{op: encode_op(transformed_op), revision: revision}}, socket}

      {:error, reason} ->
        {:reply, {:error, %{reason: inspect(reason)}}, socket}
    end
  end

  defp decode_op(%{"type" => "insert", "pos" => pos, "char" => char}) do
    {:insert, pos, char}
  end

  defp decode_op(%{"type" => "delete", "pos" => pos}) do
    {:delete, pos}
  end

  defp encode_op({:insert, pos, char}), do: %{type: "insert", pos: pos, char: char}
  defp encode_op({:delete, pos}), do: %{type: "delete", pos: pos}
  defp encode_op(:noop), do: %{type: "noop"}

  defp generate_client_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end
end
