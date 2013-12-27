defmodule ExFuture.StoreTest do
  use ExUnit.Case, async: :false

  setup_all do
    ExFuture.Store.start
    :ok
  end

  test "returning empty value" do
    key = {self, :empty_key}
    assert ExFuture.Store.get(key) == []
  end

  test "returning single value" do
    key = {self, :single}
    ExFuture.Store.push(key, "a")
    assert ExFuture.Store.get(key) == ["a"]
  end

  test "returning multiple values" do
    key = {self, :multiple}
    ExFuture.Store.push(key, "a")
    ExFuture.Store.push(key, "b")
    assert ExFuture.Store.get(key) == ["b", "a"]
  end

  test "deleting values" do
    key = {self, :delete}
    ExFuture.Store.push(key, "aa")
    assert ExFuture.Store.get(key) == ["aa"]

    ExFuture.Store.delete(key)
    assert ExFuture.Store.get(key) == []
  end
end
