defmodule ExFree do
  import Algae

  defmodule KVStore do
    defsum do
      defdata Put do
        key :: any()
        value :: any()
      end

      defdata Get do
        key :: any()
      end

      defdata Delete do
        key :: any()
      end
    end
  end

  def put(key, value) do
    Algae.Free.free(KVStore.Put.new(key, value))
  end

  def get(key) do
    Algae.Free.free(KVStore.Get.new(key))
  end

  def delete(key) do
    Algae.Free.free(KVStore.Delete.new(key))
  end

  def update(key, f) do
    use Witchcraft

    chain do
      v_maybe <- get(key)
      _ <- Algae.Free.free(v_maybe ~> fn v -> put(key, f.(v)) end)
      Algae.Free.free(Witchcraft.Unit.new())
    end
  end

  def program() do
    use Witchcraft

    chain do
      _ <- put("wild-cats", 2)
      _ <- update("wild-cats", fn v -> v + 12 end)
      _ <- put("tame-cats", 5)
      n <- get("wild-cats")
      _ <- delete("tame-cats")
      n
    end
  end

  def pure_compiler() do
    state = Algae.State.new(%{})

    fn
      %KVStore.Put{key: key, value: value} ->
        IO.puts("put(#{inspect(key)}, #{inspect(value)})")
        Algae.State.modify(fn m -> Map.put(m, key, value) end)

      %KVStore.Get{key: key} ->
        IO.puts("get(#{inspect(key)})")

        Algae.State.get(fn m ->
          case Map.get(m, key) do
            nil -> Algae.Maybe.new()
            value -> Algae.Maybe.new(value)
          end
        end)

      %KVStore.Delete{key: key} ->
        IO.puts("delete(#{inspect(key)})")
        Algae.State.modify(fn m -> Map.delete(m, key) end)
    end
  end
end

import Algae
import TypeClass

definst Witchcraft.Functor, for: Free.KVStore.Put do
  @force_type_instance true
  def map(%{key: key, value: value}, fun), do: Free.KVStore.Put.new(key, value |> fun.())
end

definst Witchcraft.Functor, for: Free.KVStore.Get do
  @force_type_instance true
  def map(get, _fun), do: get
end

definst Witchcraft.Functor, for: Free.KVStore.Delete do
  @force_type_instance true
  def map(delete, _fun), do: delete
end
