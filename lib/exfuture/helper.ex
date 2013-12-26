defmodule ExFuture.Helper do
  @doc """
  Create future with no argument. The content will be start executing right after this macro call.
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
  Create future with single argument (without tuple quoting)
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

  @doc """
  Retrive value from the future.
  """
  def value(f, params // []) do
    ExFuture.value(f, params)
  end
end
