defmodule ExFreeTest do
  use ExUnit.Case
  use Witchcraft
  doctest ExFree

  test "pure compiler" do
    pure_compiler = ExFree.pure_compiler()

    result =
      monad %Algae.State{} do
        pure_compiler.(%ExFree.KVStore.Put{key: "wild-cats", value: 2})
        pure_compiler.(%ExFree.KVStore.Put{key: "tame-cats", value: 5})
        pure_compiler.(%ExFree.KVStore.Get{key: "wild-cats"})
        pure_compiler.(%ExFree.KVStore.Delete{key: "wild-cats"})
        pure_compiler.(%ExFree.KVStore.Get{key: "wild-cats"})
        pure_compiler.(%ExFree.KVStore.Get{key: "tame-cats"})
      end

    assert Algae.State.evaluate(result, %{}) == %Algae.Maybe.Just{just: 5}
    assert Algae.State.execute(result, %{}) == %{"tame-cats" => 5}
  end
end
