defmodule ExFuture do
  defexception Error, message: nil

  defmacro __using__(_opts // []) do
    quote do
      require ExFuture
      import ExFuture.Helper
      ExFuture.Store.start
    end
  end

  defmacro new(fun) do
    wrap_fun(fun, arity_of(fun))
  end

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
            { :ok, v }    -> ExFuture.fire_on_success(self, v)
            { :error, e } -> ExFuture.fire_on_failure(self, e)
          end
          ExFuture.wait_for_request(value)
        end
      end
    end
  end

  def fire_on_success(pid, value) do
    fire_callbacks({pid, :on_success}, value)
  end

  def fire_on_failure(pid, error) do
    fire_callbacks({pid, :on_failure}, error.message)
  end

  defp fire_callbacks(key, value) do
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
        pid <- { self, value }
        if keep do
          wait_for_request(value)
        end
    end
  end

  defp arity_of({ :fn, _, [ { :->, _, [{ args, _, _ }] }] }) do
    Enum.count(args)
  end

  defp arity_of({ fun_name, _, [{ :/, _, [_, arity] }] }) when fun_name == :function or fun_name == :& do
    arity
  end

  defp arity_of(_) do
    raise Error, message: "Future.new/1 only takes functions as an argument."
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

    pid <- {self, keep}

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
    pid <- {self, true}
    receive do
      { ^pid, _ } -> nil
    end
  end

  @doc """
  Specify callback function which will be triggered when future value retrieval succeeds.
  """
  def on_success(pid, callback) do
    ExFuture.Store.push({pid, :on_success}, callback)
  end

  @doc """
  Specify callback function which will be triggered when future value retrieval fails.
  """
  def on_failure(pid, callback) do
    ExFuture.Store.push({pid, :on_failure}, callback)
  end
end