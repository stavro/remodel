defmodule RemodelTest do
  use ExUnit.Case

  defmodule TestSerializer do
    use Remodel
    attributes [:foo]
  end

  defmodule TestSerializer2 do
    use Remodel
    attribute :foo, as: :test
  end

  defmodule TestSerializer3 do
    use Remodel
    attribute :foo, if: :bar_exists

    def bar_exists(record) do
      !is_nil(record[:bar])
    end
  end

  defmodule TestSerializer4 do
    use Remodel
    attribute :foo
    attribute :bar
  end

  defmodule TestSerializer5 do
    use Remodel
    @instance_root :root
    attribute :foo
  end

  defmodule TestSerializer6 do
    use Remodel
    @array_root :root
    attribute :foo
  end

  defmodule TestSerializer7 do
    use Remodel
    attributes [:id, :mine]

    def mine(record, scope) do
      scope.id == record.id
    end
  end

  test "instance_root" do
    assert (%{foo: 1} |> TestSerializer.to_map(instance_root: :root)) == %{root: %{foo: 1}}
    assert ([%{foo: 1}] |> TestSerializer.to_map(instance_root: :root)) == [%{root: %{foo: 1}}]
    assert ([%{foo: 1}] |> TestSerializer5.to_map) == [%{root: %{foo: 1}}]
  end

  test "array_root" do
    assert (%{foo: 1} |> TestSerializer.to_map(array_root: :root)) == %{foo: 1}
    assert ([%{foo: 1}] |> TestSerializer.to_map(array_root: :root)) == %{root: [%{foo: 1}]}
    assert ([%{foo: 1}] |> TestSerializer.to_map(array_root: :root, instance_root: :root2)) == %{root: [%{root2: %{foo: 1}}]}
    assert ([%{foo: 1}] |> TestSerializer6.to_map) == %{root: [%{foo: 1}]}
  end

  test "model to_map" do
    assert (%{foo: 1} |> TestSerializer.to_map) == %{foo: 1}
    assert (%{foo: 1} |> TestSerializer2.to_map) == %{test: 1}
    assert (%{foo: 1} |> TestSerializer3.to_map) == %{}
    assert (%{foo: 1, bar: 2} |> TestSerializer3.to_map) == %{foo: 1}
  end

  test "list of models to_map" do
    assert ([%{foo: 1}] |> TestSerializer.to_map) == [%{foo: 1}]
    assert ([%{foo: 1}, %{foo: 2}] |> TestSerializer.to_map) == [%{foo: 1},%{foo: 2}]
  end

  test "to_list" do
    assert (%{foo: 1} |> TestSerializer.to_list(headers: true)) == [["foo"],[1]]
    assert (%{foo: 1} |> TestSerializer2.to_list) == [1]
    assert (%{foo: 1} |> TestSerializer3.to_list(headers: true)) == [["foo"], [nil]]
    assert (%{foo: 1, bar: 2} |> TestSerializer3.to_list(headers: true)) == [["foo"], [1]]
  end

  test "list of models to_list" do
    assert ([%{foo: 1}] |> TestSerializer4.to_list(headers: true)) == [["foo", "bar"],[1,nil]]
    assert ([%{foo: 1, bar: 2}, %{foo: 2}] |> TestSerializer4.to_list(headers: true)) == [["foo", "bar"],[1, 2],[2, nil]]
    assert ([%{foo: 1, bar: 2}, %{foo: 2}] |> TestSerializer4.to_list) == [[1, 2],[2, nil]]
  end

  test "scope" do
    assert (%{id: 1} |> TestSerializer7.to_map(scope: %{id: 1})) == %{id: 1, mine: true}
    assert (%{id: 2} |> TestSerializer7.to_list(headers: true, scope: %{id: 1})) == [["id","mine"],[2,false]]
  end
end
