defmodule ExFuture.HelperTest do
  use ExUnit.Case
  use ExFuture

  test "future block with no arguments" do
    f = future do
      3 * 3
    end
    assert 9 == resolve(f)
  end

  test "future block with one argument" do
    f = future(x) do
      x * x
    end
    f1 = f.(3)
    assert 9 == resolve(f1)
  end

  test "future block with multiple arguments" do
    f = future({x, y}) do
      x + y
    end
    f1 = f.({1, 2})
    assert 3 == resolve(f1)
  end

  test "resolve macro" do
    i = 3
    f = future do i * 2 end
    assert resolve(f) == 6
  end

  test "parallel map with future/resolve macro" do
    v = [1, 2, 3]
          |> Enum.map(future(x) do x * 2 end)
          |> Enum.map(resolve)
    assert v == [2, 4, 6]
  end

end