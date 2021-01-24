defmodule AdafruitLedBackpack.Interface do
  @type bus_name :: String.t()
  @type bus :: any()
  @type address :: byte()
  @type data :: iodata()

  @callback open(bus_name()) :: {:ok, bus()} | {:error, reason :: any()}
  @callback write!(bus(), address(), data()) :: :ok
end
