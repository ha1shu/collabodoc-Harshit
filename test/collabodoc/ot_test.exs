defmodule Collabodoc.OTTest do
  use ExUnit.Case, async: true
  alias Collabodoc.OT

  describe "apply_op/2" do
    test "insert into empty doc" do
      assert OT.apply_op("", {:insert, 0, "a"}) == "a"
    end

    test "insert in middle" do
      assert OT.apply_op("hllo", {:insert, 1, "e"}) == "hello"
    end

    test "delete a character" do
      assert OT.apply_op("hello", {:delete, 1}) == "hllo"
    end

    test "insert at out-of-bounds clamps to end" do
      assert OT.apply_op("hi", {:insert, 99, "!"}) == "hi!"
    end
  end

  describe "transform/2" do
    test "two inserts at same position" do
      op_a = {:insert, 2, "X"}
      op_b = {:insert, 2, "Y"}
      assert OT.transform(op_a, op_b) == {:insert, 3, "X"}
    end

    test "insert before another insert" do
      op_a = {:insert, 5, "X"}
      op_b = {:insert, 2, "Y"}
      assert OT.transform(op_a, op_b) == {:insert, 6, "X"}
    end

    test "insert after another insert" do
      op_a = {:insert, 2, "X"}
      op_b = {:insert, 5, "Y"}
      assert OT.transform(op_a, op_b) == {:insert, 2, "X"}
    end

    test "two deletes at same position becomes noop" do
      assert OT.transform({:delete, 3}, {:delete, 3}) == :noop
    end

    test "delete after a prior delete shifts left" do
      op_a = {:delete, 5}
      op_b = {:delete, 2}
      assert OT.transform(op_a, op_b) == {:delete, 4}
    end
  end
end
