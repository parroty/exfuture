# ExFuture [![Build Status](https://secure.travis-ci.org/parroty/exfuture.png?branch=master "Build Status")](http://travis-ci.org/parroty/exfuture) [![Coverage Status](https://coveralls.io/repos/parroty/exfuture/badge.png)](https://coveralls.io/r/parroty/exfuture)


A trial implementation of future, inspired by

- Future (https://github.com/eproxus/future)
- akka (http://doc.akka.io/docs/akka/snapshot/scala/futures.html)


### Usage
```Elixir
defmodule ExFuture.HelperTest do
  use ExUnit.Case
  use ExFuture

  test "future block" do
    f = future do
      3 * 3
    end
    assert 9 == value(f)
  end

  test "parallel map with future/value macro using collection" do
    v = [1, 2, 3]
          |> Enum.map(future(&(&1 * 2)))
          |> Enum.map(&(value(&1)))
    assert v == [2, 4, 6]
  end

  test "parallel map for getting html pages" do
    HTTPotion.start
    # Dummy http server to return a response after 1 second.
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
```

### Examples
Some more examples.

https://github.com/parroty/exfuture/blob/master/test/exfuture_test.exs
https://github.com/parroty/exfuture/blob/master/test/helper_test.exs
