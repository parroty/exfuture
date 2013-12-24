defmodule ExFuture do
  use Application.Behaviour

  # See http://elixir-lang.org/docs/stable/Application.Behaviour.html
  # for more information on OTP Applications
  def start(_type, _args) do
    ExFuture.Supervisor.start_link
  end

  defexception Error, message: nil

  @doc """
  future macro with no argument. The content will be start executing right after this macro call.
     future do
       3 * 3
     end
  """
  defmacro future([do: content]) do
    f = quote do
      fn -> unquote(content) end
    end
    wrap_fun(f, 0) |> call_fun([])
  end


  @doc """
  future macro with arguments.
  The content will be start executing once arguments are being passed as arguments.
     future({x, y}) do
       x + y
     end
  """
  defmacro future(tuple, [do: content]) when is_tuple(tuple) do
    f = quote do
      fn(unquote(tuple)) -> unquote(content) end
    end
    wrap_fun(f, 1)
  end

  @doc """
  future macro with single argument (without tuple quoting)
  The content will be start executing once arguments are being passed as arguments.
     future(x) do
       x * x
     end
  """
  defmacro future(arg, [do: content]) do
    f = quote do
      fn(unquote(arg)) -> unquote(content) end
    end
    wrap_fun(f, 1)
  end

  defmacro resolve do
    quote do
      fn(x) -> ExFuture.value(x) end
    end
  end

  def resolve(f) do
    ExFuture.value(f)
  end

  defmacro new(fun) do
    wrap_fun(fun, arity_of(fun))
  end

  defmacro new(fun, arity) do
    wrap_fun(fun, arity)
  end

  defp wrap_fun(fun, arity) do
    args = init_args(arity)

    quote do
      fn(unquote_splicing(args)) ->
        spawn_link fn ->
          value = try do
            { :ok, unquote(call_fun(fun, args)) }
        rescue
          e -> { :error, e }
        end

        receive do
          pid ->
            pid <- { self, value }
          end
        end
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
  def value(pid, timeout // :infinity, default // { :error, :timeout }) do
    unless Process.alive? pid do
      raise Error, message: "exhausted"
    end
    pid <- self
    receive do
      { ^pid, { :ok, value } } -> value
      { ^pid, { :error, e } }  -> raise e
    after
      timeout -> default
    end
  end
end