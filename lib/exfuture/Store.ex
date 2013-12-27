defmodule ExFuture.Store do
  @moduledoc """
  Provides ETS based data store.
  """
  @ets_table :exfuture

  def start do
    if :ets.info(@ets_table) == :undefined do
      :ets.new(@ets_table, [:set, :public, :named_table])
    end
    :ok
  end

  def push(key, callback) do
    value = get(key)
    :ets.insert(@ets_table, {key, [callback | value]})
  end

  def get(key) do
    :ets.lookup(@ets_table, key)[key] || []
  end

  def delete(key) do
    :ets.delete(@ets_table, key)
  end
end