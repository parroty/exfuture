defmodule ExFutureTest do
  use ExUnit.Case
  import CompileAssertion
  use ExFuture

  def square(x), do: x * x
  test "parallel map" do
    v = [1, 2, 3]
          |> Enum.map(ExFuture.new(&square/1))
          |> Enum.map(&ExFuture.value(&1))
    assert v == [1, 4, 9]
  end

  test "future with no arguments" do
    f = ExFuture.new(fn -> 3 * 3 end)
    f1 = f.()
    assert 9 == ExFuture.value(f1)
  end

  test "two futures" do
    f = ExFuture.new(fn x -> x end)
    f1 = f.(1)
    f2 = f.(2)
    assert 1 == ExFuture.value(f1)
    assert 2 == ExFuture.value(f2)
  end

  test "raises" do
    assert_raise RuntimeError, "test", fn ->
      ExFuture.value ExFuture.new(fn _ -> raise "test" end).(1)
    end
  end

  test "exhaustion" do
    f = ExFuture.new(fn x -> x end).(1)
    assert 1 == ExFuture.value f
    assert_raise ExFuture.Error, "exhausted", fn ->
      ExFuture.value f
    end
  end

  test "exhaustion doesn't occur if keep param is specified" do
    f = ExFuture.new(fn x -> x end).(1)
    assert 1 == ExFuture.value(f, keep: true)
    assert 1 == ExFuture.value(f)
    assert_raise ExFuture.Error, "exhausted", fn ->
      ExFuture.value f
    end
  end

  test "a future with multiple arguments" do
    f = ExFuture.new(fn x, y, z -> x + y + z end)
    f1 = f.(1, 2, 3)
    assert 6 == ExFuture.value(f1)
  end

  def addition(x,y) do
    x + y
  end

  test "a future with a &function argument" do
    f = ExFuture.new(&addition/2)
    f1 = f.(1,2)
    assert 3 == ExFuture.value(f1)
  end

  test "calling a future with a non function value raises an error" do
    assert_compile_fail ExFuture.Error, "import ExFuture; ExFuture.new(10)"
  end

  test "a future with function and arity" do
    func = fn x, y -> x + y end
    f = ExFuture.new(func, 2)
    f1 = f.(3, 4)
    assert 7 == ExFuture.value(f1)
  end
end
