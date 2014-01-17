defmodule ExFuture do
  @moduledoc """
  Provide future functionalities.
  """

  defexception Error, message: nil

  defmacro __using__(_opts // []) do
    quote do
      require ExFuture
      import ExFuture.Helper
      ExFuture.Store.start
    end
  end

  @doc """
  Create future.
  """
  defmacro new(arg) do
    if is_func(arg) do
      wrap_fun(arg, arity_of(arg))
    else
      from_value(arg)
    end
  end

  defp is_func(fun) do
    case fun do
      {:fn, _, _} -> true
      {:&, _, _}  -> true
      _           -> false
    end
  end

  @doc """
  Create future from value.
  """
  def from_value(value) do
    f = quote do
      fn -> unquote(value) end
    end
    ExFuture.wrap_fun(f, 0) |> call_fun([])
  end

  @doc """
  Create future from a function with specific arity information.
  """
  defmacro new(fun, arity) do
    wrap_fun(fun, arity)
  end

  def wrap_fun(fun, arity) do
    args = init_args(arity)

    quote do
      fn(unquote_splicing(args)) ->
        spawn_link fn ->
          value = try do
            { :ok, unquote(call_fun(fun, args)) }
          rescue
            e -> { :error, e }
          end

          case value do
            { :ok, v }    -> ExFuture.trigger_on_success(self, v)
            { :error, e } -> ExFuture.trigger_on_failure(self, e)
          end

          ExFuture.wait_for_request(value)
        end
      end
    end
  end

  @doc """
  Fire on_success callback when future value becomes ready.
  """
  def trigger_on_success(pid, value) do
    trigger_callbacks({pid, :on_success}, value)
    trigger_callbacks({pid, :on_complete}, {:on_success, value})
  end

  @doc """
  Fire on_failure callback when future value retrieval failed.
  """
  def trigger_on_failure(pid, error) do
    trigger_callbacks({pid, :on_failure}, error.message)
    trigger_callbacks({pid, :on_complete}, {:on_failure, error.message})
  end

  defp trigger_callbacks(key, value) do
    ExFuture.Store.get(key) |> Enum.each(fn(fun) -> fun.(value) end)
    ExFuture.Store.delete(key)
  end

  @doc """
  Wait for future value reference to arrive.
  If keep flag is set as true, keeps maitanining the value.
  """
  def wait_for_request(value) do
    receive do
      { pid, keep } ->
        send pid, { self, value }
        if keep do
          wait_for_request(value)
        end
    end
  end

  defp arity_of({ :fn, _, [ { :->, _, [{ args, _, _ }] }] }) do
    Enum.count(args)
  end

  # Added for elixir v0.12.1 or later
  defp arity_of({ :fn, _, [ { :->, _, [args, _] }] }) do
    Enum.count(args)
  end

  defp arity_of({ fun_name, _, [{ :/, _, [_, arity] }] }) when fun_name == :function or fun_name == :& do
    arity
  end

  defp init_args(0), do: []
  defp init_args(arity) do
    Enum.map(1..arity, fn x -> { :"x#{x}", [], nil } end)
  end

  defp call_fun(fun, []) do
    quote do unquote(fun).() end
  end

  defp call_fun(fun, args) do
    quote do unquote(fun).(unquote_splicing(args)) end
  end

  @doc """
  Resolve the value of the future. If the value is not ready yet,
  it waits until the value becomes ready or reaches the timeout.
  """
  def value(pid, params // []) do
    keep    = params[:keep] || false
    timeout = params[:timeout] || :infinity
    default = params[:default] || { :error, :timeout }

    unless Process.alive? pid do
      raise Error, message: "exhausted"
    end

    send pid, {self, keep}

    receive do
      { ^pid, { :ok, value } } -> value
      { ^pid, { :error, e } }  -> raise e
    after
      timeout -> default
    end
  end

  @doc """
  Wait for the future value to be ready. It doesn't return value itself
  """
  def wait(pid) do
    send pid, {self, true}
    receive do
      { ^pid, _ } -> nil
    end
  end

  @doc """
  Specify callback function which will be triggered when future value retrieval succeeds.
  It returns retrieved value.
  """
  def on_success(pid, callback) do
    ExFuture.Store.push({pid, :on_success}, callback)
  end

  @doc """
  Specify callback function which will be triggered when future value retrieval fails.
  It returns error message.
  """
  def on_failure(pid, callback) do
    ExFuture.Store.push({pid, :on_failure}, callback)
  end

  @doc """
  Specify callback function which will be triggered when future value completes.
  It returns either of {:on_success, value} or {:on_falure, error_message}
  """
  def on_complete(pid, callback) do
    ExFuture.Store.push({pid, :on_complete}, callback)
  end

  @doc """
  Provide map operation for the future.
  """
  defmacro map(pid, fun) do
    quote do
      spawn_link fn ->
        value = ExFuture.value(unquote(pid))
        ExFuture.wait_for_request({:ok, unquote(fun).(value)})
      end
    end
  end

  @doc """
  Provide zip operation for the future.
  """
  defmacro zip(pid1, pid2, fun) do
    quote do
      spawn_link fn ->
        value1 = ExFuture.value(unquote(pid1))
        value2 = ExFuture.value(unquote(pid2))
        ExFuture.wait_for_request({:ok, unquote(fun).(value1, value2)})
      end
    end
  end

  @doc """
  Convert List(Future(v)) to Future(List(v)).
  """
  defmacro sequence(list) do
    quote do
      ExFuture.new(fn ->
        Enum.map(unquote(list), fn(x) -> ExFuture.value(x) end)
      end).()
    end
  end
end
