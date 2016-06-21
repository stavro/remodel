defmodule Remodel.Formatter.MapFormatter do
  def format(resource, serializer, options) do
    format_resource(resource, serializer, options)
    |> put_meta(options[:meta])
  end

  defp format_resource(resources, serializer, options) when is_list(resources) do
    Enum.map(resources, fn(resource) ->
      format_resource(resource, serializer, options)
    end) |> wrap(options.array_root)
  end

  defp format_resource(resource, serializer, options) when is_map(resource) do
    Enum.reduce(serializer.__attributes, %{}, fn(attr, results) ->
      if !attr.if || evaluate_conditional(resource, serializer, options, attr) do
        Map.put(results, attr.as || attr.attribute, apply(serializer, attr.attribute, [resource, options[:scope]]))
      else
        results
      end
    end) |> wrap(options.instance_root)
  end

  defp evaluate_conditional(resource, serializer, options, attr),
    do: apply(serializer, attr.if, [resource, options[:scope]])

  defp put_meta(results, meta) when is_map(meta),
    do: Map.put(results, "meta", meta)
  defp put_meta(results, _meta), do: results

  defp wrap(value, key) when is_nil(key),
    do: value
  defp wrap(value, key),
    do: Dict.put(%{}, key, value)
end
