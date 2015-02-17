defmodule Remodel.Schema do
  alias Remodel.Schema
  alias Remodel.Attribute

  defmacro __using__(_) do
    quote do
      Module.register_attribute __MODULE__, :attributes, accumulate: true
      @instance_root nil
      @array_root nil
      import Schema, only: [attributes: 1, attributes: 2, attribute: 1, attribute: 2]
      @before_compile Schema
    end
  end

  defmacro attributes(attrs, options \\ []) do
    quote bind_quoted: [attrs: attrs, options: options] do
      Enum.each attrs, &(attribute(&1, options))
    end
  end

  defmacro attribute(attr, options \\ []) do
    quote bind_quoted: [attr: attr, options: options] do
      require Attribute
      Attribute.define(attr, options)
      @attributes %Attribute{attribute: attr, as: options[:as], if: options[:if]}
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def __instance_root, do: @instance_root
      def __array_root, do: @array_root
      def __attributes, do: @attributes |> Enum.reverse

      def to_map(resource, options \\ []) do
        Remodel.Formatter.MapFormatter.format resource, __MODULE__, (options |> list_to_map |> apply_defaults)
      end

      def to_list(resource, options \\ []) do
        Remodel.Formatter.ListFormatter.format resource, __MODULE__, (options |> list_to_map |> apply_defaults)
      end
      
      defp list_to_map(options) when is_list(options),
        do: Enum.into(options, %{})
      defp list_to_map(options),
        do: options

      defp apply_defaults(options) do
        if !Map.has_key?(options, :instance_root),
          do: options = Dict.put(options, :instance_root, @instance_root)

        if !Map.has_key?(options, :array_root),
          do: options = Dict.put(options, :array_root, @array_root)

        options
      end

    end
  end
end
