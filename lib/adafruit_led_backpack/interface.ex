defmodule AdafruitLedBackpack.Interface do
  @type bus_name :: String.t()
  @type bus :: any()
  @type address :: byte()

  @callback open(bus_name()) :: {:ok, bus()} | {:error, reason :: any()}
  @callback write!(bus(), address(), iodata()) :: :ok
end
