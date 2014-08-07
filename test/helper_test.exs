defmodule ExFuture.HelperTest do
  use ExUnit.Case, async: :false
  use ExFuture

  setup_all do
    ExFuture.Store.start
    HTTPotion.start
    :ok
  end

  test "future block" do
    f = future do
      3 * 3
    end
    assert 9 == value(f)
  end

  test "future block with external parameter" do
    i = 3
    f = future do
      i * 2
    end
    assert value(f) == 6
  end

  test "future block with one argument" do
    f = future(x) do
      x * x
    end
    assert 9 == value(f.(3))
  end

  test "future block with one function argument" do
    f = future(fn(x) -> x * x end)
    assert 9 == value(f.(3))
  end

  test "parallel map with future/value macro using collection" do
    v = [1, 2, 3]
          |> Enum.map(future(&(&1 * 2)))
          |> Enum.map(&(value(&1)))
    assert v == [2, 4, 6]
  end

  test "parallel map with future/value macro using range" do
    v = 1..10
          |> Enum.map(future(&(&1 * 2)))
          |> Enum.map(&(value(&1)))
    assert v == Enum.map(1..10, fn(x) -> x * 2 end)
  end

  test "parallel map for getting html pages" do
    HttpServer.start(path: "/test", port: 4000,
                     response: "Custom Response", wait_time: 1000)

    # 10 requests, which each takes 1 second.
    links = List.duplicate("http://localhost:4000/test", 10)

    s = :erlang.now
    htmls = links
              |> Enum.map(future(&(HTTPotion.get(&1).body)))
              |> Enum.map(&(value(&1)))

    # It should take more than 1 second, but it should be less than
    # 2 seconds, by the parallel execution.
    time = :timer.now_diff(:erlang.now, s)
    assert(time >= 1_000_000 and time <= 2_000_000)

    assert htmls == List.duplicate("Custom Response", 10)
  end

  test "value(future) raise exception if acuiring value fails" do
    f = future do
      HTTPotion.get("http://localhost:1111")
    end
    assert_raise HTTPotion.HTTPError, fn -> value(f) end
  end

  test "map on future for async chaining" do
    i = 1
    f = future(i * 2) |> map(&(&1 * 3)) |> map(&(&1 * 4))
    assert 24 == value(f)
  end

  test "zip on future for async chaining" do
    f1 = future(1)
    f2 = future(2)
    f3 = zip(f1, f2, &(&1 + &2))
    assert 3 == value(f3)
  end

  test "reduce on future" do
    f = for v <- [1, 2, 3], do: future(v)
    assert 6 == Enum.reduce(f, 0, &(value(&1) + &2))
  end
end
