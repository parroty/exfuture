defmodule ExFuture.Helper do
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
    wrap_fun(f, 0) |> call_fun
  end

  defp call_fun(fun) do
    quote do unquote(fun).() end
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

  defp wrap_fun(fun, arity) do
    ExFuture.wrap_fun(fun, arity)
  end

  def resolve(timeout // :infinity, default // { :error, :timeout }) do
    fn(x) -> ExFuture.value(x, timeout, default) end
  end

  def value(f, timeout // :infinity, default // { :error, :timeout }) do
    ExFuture.value(f, timeout, default)
  end
end