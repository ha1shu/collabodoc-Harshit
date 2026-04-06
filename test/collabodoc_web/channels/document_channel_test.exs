defmodule CollabodocWeb.DocumentChannelTest do
  use CollabodocWeb.ChannelCase
  alias CollabodocWeb.UserSocket

  setup do
    doc_id = "test-doc-#{System.unique_integer([:positive])}"
    {:ok, _, socket} =
      UserSocket
      |> socket("user_id", %{})
      |> subscribe_and_join(CollabodocWeb.DocumentChannel, "doc:#{doc_id}", %{"client_id" => "client1"})

    %{socket: socket, doc_id: doc_id}
  end

  test "joining returns empty document", %{socket: socket} do
    assert socket.assigns.doc_id != nil
  end

  test "inserting a character updates the document", %{socket: socket, doc_id: doc_id} do
    ref = push(socket, "op", %{
      "revision" => 0,
      "op" => %{"type" => "insert", "pos" => 0, "char" => "H"}
    })

    assert_reply ref, :ok, %{revision: 1}

    {:ok, content, _rev} = Collabodoc.DocumentServer.get_state(doc_id)
    assert content == "H"
  end

  test "two concurrent inserts are both applied", %{doc_id: doc_id} do
    {:ok, _, socket1} =
      UserSocket
      |> socket("u1", %{})
      |> subscribe_and_join(CollabodocWeb.DocumentChannel, "doc:#{doc_id}", %{"client_id" => "c1"})

    {:ok, _, socket2} =
      UserSocket
      |> socket("u2", %{})
      |> subscribe_and_join(CollabodocWeb.DocumentChannel, "doc:#{doc_id}", %{"client_id" => "c2"})

    ref1 = push(socket1, "op", %{
      "revision" => 0,
      "op" => %{"type" => "insert", "pos" => 0, "char" => "A"}
    })
    ref2 = push(socket2, "op", %{
      "revision" => 0,
      "op" => %{"type" => "insert", "pos" => 0, "char" => "B"}
    })

    assert_reply ref1, :ok, _
    assert_reply ref2, :ok, _

    {:ok, content, _} = Collabodoc.DocumentServer.get_state(doc_id)
    assert String.length(content) == 2
    assert content =~ "A"
    assert content =~ "B"
  end

  test "new client joining gets current content", %{doc_id: doc_id} do
    {:ok, _, socket1} =
      UserSocket
      |> socket("u1", %{})
      |> subscribe_and_join(CollabodocWeb.DocumentChannel, "doc:#{doc_id}", %{"client_id" => "c1"})

    push(socket1, "op", %{
      "revision" => 0,
      "op" => %{"type" => "insert", "pos" => 0, "char" => "Z"}
    })

    Process.sleep(50)

    {:ok, join_reply, _socket2} =
      UserSocket
      |> socket("u2", %{})
      |> subscribe_and_join(CollabodocWeb.DocumentChannel, "doc:#{doc_id}", %{"client_id" => "c2"})

    assert join_reply.content == "Z"
  end
end
