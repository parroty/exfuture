defmodule ExFutureTest do
  use ExUnit.Case, async: :false
  import ExUnit.CaptureIO
  use ExFuture

  setup_all do
    ExFuture.Store.start
    :ok
  end

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

  test "a future with function and arity" do
    func = fn x, y -> x + y end
    f = ExFuture.new(func, 2)
    f1 = f.(3, 4)
    assert 7 == ExFuture.value(f1)
  end

  test "single on_success callback" do
    assert capture_io(fn ->
      f = ExFuture.new(fn -> 3 * 3 end).()
      ExFuture.on_success(f, fn(x) -> IO.puts "value = #{x}" end)
      ExFuture.wait(f)
    end) == "value = 9\n"
  end

  test "multiple on_success callbacks" do
    assert capture_io(fn ->
      f = ExFuture.new(fn -> 3 * 3 end).()
      ExFuture.on_success(f, fn(x) -> IO.puts "value1 = #{x}" end)
      ExFuture.on_success(f, fn(x) -> IO.puts "value2 = #{x}" end)
      ExFuture.wait(f)
    end) == "value2 = 9\nvalue1 = 9\n"
  end

  test "single on_failure callback" do
    assert capture_io(fn ->
      f = ExFuture.new(fn -> HTTPotion.get("http://localhost:1111") end).()
      ExFuture.on_failure(f, fn(x) -> IO.puts "value = #{x}" end)
      ExFuture.wait(f)
    end) == "value = argument error\n"
  end

  test "on_complete callback with success case" do
    assert capture_io(fn ->
      f = ExFuture.new(fn -> 3 * 3 end).()
      ExFuture.on_complete(f, fn(x) ->
        case x do
          {:on_success, v} -> IO.puts "success with value = #{v}"
          {:on_failure, e} -> IO.puts "failure with error = #{e}"
        end
      end)
      ExFuture.wait(f)
    end) == "success with value = 9\n"
  end

  test "on_complete callback with failure case" do
    assert capture_io(fn ->
      f = ExFuture.new(fn -> HTTPotion.get("http://localhost:1111") end).()
      ExFuture.on_complete(f, fn(x) ->
        case x do
          {:on_success, v} -> IO.puts "success with value = #{v}"
          {:on_failure, e} -> IO.puts "failure with error = #{e}"
        end
      end)
      ExFuture.wait(f)
    end) == "failure with error = argument error\n"
  end

  test "map on future for async chaining" do
    i = 3
    f1 = ExFuture.new(fn -> i * 3 end).()
    f2 = ExFuture.map(f1, fn(x) -> x * 3 end)
    assert 27 == ExFuture.value(f2)
  end

  test "zip on future for async chaining" do
    f1 = ExFuture.new(fn -> 1 end).()
    f2 = ExFuture.new(fn -> 2 end).()
    f3 = ExFuture.zip(f1, f2, fn(x, y) -> x + y end)
    assert 3 == ExFuture.value(f3)
  end

  test "reduce on future" do
    f = lc v inlist [1, 2, 3], do: ExFuture.new(v)
    sum = Enum.reduce(f, 0, fn(x, acc) -> ExFuture.value(x) + acc end)
    assert 6 == sum
  end
end
