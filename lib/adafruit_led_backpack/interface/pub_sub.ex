if Code.ensure_loaded?(Phoenix.PubSub) do
  defmodule AdafruitLedBackpack.Interface.PubSub do
    @behaviour AdafruitLedBackpack.Interface

    alias Phoenix.PubSub

    @impl AdafruitLedBackpack.Interface
    def open(bus_name) do
      name = table_name(bus_name)

      :ets.new(name, [
        :public,
        :named_table,
        {:read_concurrency, true},
        {:write_concurrency, true}
      ])

      {:ok, bus_name}
    rescue
      ArgumentError -> {:ok, bus_name}
    end

    defp table_name(bus_name) do
      String.to_atom("#{inspect(__MODULE__)}_#{bus_name}")
    end

    def subscribe(bus_name, address) do
      topic = pubsub_topic(bus_name, address)

      with :ok <- PubSub.subscribe(AdafruitLedBackpack.PubSub, topic) do
        {:ok,
         bus_name
         |> table_name()
         |> :ets.tab2list()
         |> Map.new()}
      end
    rescue
      ArgumentError -> {:ok, %{}}
    end

    defp pubsub_topic(bus_name, address) do
      "#{inspect(__MODULE__)}_#{bus_name}_#{address}"
    end

    @impl AdafruitLedBackpack.Interface
    def write!(bus_name, address, iodata) do
      name = table_name(bus_name)
      data = IO.iodata_to_binary(iodata)

      case byte_size(data) do
        1 ->
          :ets.insert(name, {data, 0})

        _ ->
          for <<register::8, value::8 <- data>> do
            :ets.insert(name, {register, value})
          end
      end

      topic = pubsub_topic(bus_name, address)
      data = name |> :ets.tab2list() |> Map.new()
      message = {__MODULE__, bus_name, address, data}
      PubSub.broadcast!(AdafruitLedBackpack.PubSub, topic, message)
    end
  end
end
