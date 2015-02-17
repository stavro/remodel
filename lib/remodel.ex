defmodule Remodel do
  defmacro __using__(_) do
    quote do
      use Remodel.Schema
    end
  end
end
