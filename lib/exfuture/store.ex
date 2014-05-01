defmodule ExFuture.Store do
  @moduledoc """
  Provide ETS based data store.
  """
  @ets_table :exfuture

  def start do
    if :ets.info(@ets_table) == :undefined do
      :ets.new(@ets_table, [:set, :public, :named_table])
    end
    :ok
  end

  def push(key, callback) do
    key = to_atom(key)
    value = ExFuture.Store.get(key) # add full module name for avoiding weird error at excoveralls
    :ets.insert(@ets_table, {key, [callback | value]})
  end

  def get(key) do
    key = to_atom(key)
    :ets.lookup(@ets_table, key)[key] || []
  end

  def delete(key) do
    key = to_atom(key)
    :ets.delete(@ets_table, key)
  end

  def to_atom(key) do
    if is_atom(key) do
      key
    else
      key |> inspect |> binary_to_atom
    end
  end
end