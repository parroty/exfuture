defmodule ExFuture do
  use Application.Behaviour

  # See http://elixir-lang.org/docs/stable/Application.Behaviour.html
  # for more information on OTP Applications
  def start(_type, _args) do
    ExFuture.Supervisor.start_link
  end

  defexception Error, message: nil

  defmacro future([do: content]) do
    f = quote do
      fn -> unquote(content) end
    end
    IO.inspect f
    IO.inspect arity_of(f)
    IO.inspect wrap_fun(f, 0)
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