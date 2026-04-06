defmodule Collabodoc.OT do
  @moduledoc """
  Operational Transformation for plain-text documents.

  An operation is one of:
    {:insert, position, char}
    {:delete, position}

  transform(op_a, op_b) returns op_a transformed against op_b,
  assuming op_b has already been applied to the document.
  """

  @doc """
  Transform op_a so it can be applied AFTER op_b has already been applied.
  """
  def transform({:insert, pos_a, char}, {:insert, pos_b, _char_b}) do
    if pos_b <= pos_a do
      {:insert, pos_a + 1, char}
    else
      {:insert, pos_a, char}
    end
  end

  def transform({:insert, pos_a, char}, {:delete, pos_b}) do
    if pos_b < pos_a do
      {:insert, pos_a - 1, char}
    else
      {:insert, pos_a, char}
    end
  end

  def transform({:delete, pos_a}, {:insert, pos_b, _char_b}) do
    if pos_b <= pos_a do
      {:delete, pos_a + 1}
    else
      {:delete, pos_a}
    end
  end

  def transform({:delete, pos_a}, {:delete, pos_b}) do
    cond do
      pos_b < pos_a -> {:delete, pos_a - 1}
      pos_b == pos_a -> :noop
      true -> {:delete, pos_a}
    end
  end

  @doc """
  Apply an operation to a document string. Returns the new string.
  """
  def apply_op(doc, {:insert, pos, char}) do
    pos = min(pos, String.length(doc))
    pos = max(pos, 0)
    {before, after_} = String.split_at(doc, pos)
    before <> char <> after_
  end

  def apply_op(doc, {:delete, pos}) do
    len = String.length(doc)
    if pos < 0 or pos >= len do
      doc
    else
      {before, rest} = String.split_at(doc, pos)
      {_deleted, after_} = String.split_at(rest, 1)
      before <> after_
    end
  end

  def apply_op(doc, :noop), do: doc
end
