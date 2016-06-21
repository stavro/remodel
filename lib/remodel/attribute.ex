defmodule Remodel.Attribute do
  defstruct [:attribute, :as, :if]

  defmacro define(attr, options) do
    quote bind_quoted: [attr: attr, options: options] do
      import Remodel.Attribute, only: [define_conditional: 1, define_attr_accessor: 1]
      define_conditional options[:if]
      define_attr_accessor attr
    end
  end

  defmacro define_conditional(nil), do: nil
  defmacro define_conditional(cond_func) do
    quote bind_quoted: [cond_func: cond_func] do
      def unquote(cond_func)(record, scope), do: apply(__MODULE__, unquote(cond_func), [record])
      def unquote(cond_func)(record),        do: false
      defoverridable [{cond_func, 1}, {cond_func, 2}]
    end
  end

  defmacro define_attr_accessor(attr) do
    quote bind_quoted: [attr: attr] do

      def unquote(attr)(record),        do: Map.get(record, unquote(attr))
      def unquote(attr)(record, scope), do: apply(__MODULE__, unquote(attr), [record])
      defoverridable [{attr, 1}, {attr, 2}]
    end
  end

end
