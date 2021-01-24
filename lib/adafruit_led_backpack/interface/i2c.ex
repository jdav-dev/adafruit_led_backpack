defmodule AdafruitLedBackpack.Interface.I2C do
  @behaviour AdafruitLedBackpack.Interface

  @impl AdafruitLedBackpack.Interface
  defdelegate open(bus_name), to: Circuits.I2C

  @impl AdafruitLedBackpack.Interface
  defdelegate write!(i2c_bus, address, data), to: Circuits.I2C
end
