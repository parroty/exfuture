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
    ExFuture.wrap_fun(f, 0) |> call_fun
  end

  @doc """
  Create future with single function argument (without tuple quoting).
  The content will be start executing once arguments are being passed as arguments.
     future(fn -> 3 * 3 end)
  """
  defmacro future({:fn, _, _} = fun), do: ExFuture.wrap_fun(fun, 1)
  defmacro future({:&, _, _} = fun), do:  ExFuture.wrap_fun(fun, 1)

  @doc """
  Create future with single value argument (without tuple quoting).
  The content will be start executing once arguments are being passed as arguments.
     future(3)
  """
  defmacro future(value) do
    f = quote do
      fn -> unquote(value) end
    end
    ExFuture.wrap_fun(f, 0) |> call_fun
  end

  @doc """
  Create future with single argument (without tuple quoting).
  The content will be start executing once arguments are being passed as arguments.
     future(x) do
       x * x
     end
  """
  defmacro future(arg, [do: content]) do
    f = quote do
      fn(unquote(arg)) -> unquote(content) end
    end
    ExFuture.wrap_fun(f, 1)
  end

  defp call_fun(fun) do
    quote do unquote(fun).() end
  end

  @doc """
  Retrive value from the future.
  """
  def value(f, params // []) do
    ExFuture.value(f, params)
  end

  @doc """
  Map operation for future for chaining.
  """
  defmacro map(pid, fun) do
    quote do
      ExFuture.map(unquote(pid), unquote(fun))
    end
  end
end
