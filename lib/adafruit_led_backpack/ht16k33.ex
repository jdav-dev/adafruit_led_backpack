defmodule AdafruitLedBackpack.Ht16k33 do
  @moduledoc "Driver for interfacing with a Holtek HT16K33 16x8 LED driver."

  use GenServer

  import Bitwise

  alias Circuits.I2C

  # TODO: Use Agent instead of GenServer?

  @default_bus_name "i2c-1"
  @default_address 0x70

  @ht16k33_blink_cmd 0x80
  @ht16k33_blink_displayon 0x01
  @ht16k33_blink_off 0x00
  @ht16k33_blink_2hz 0x02
  @ht16k33_blink_1hz 0x04
  @ht16k33_blink_halfhz 0x06
  @ht16k33_system_setup 0x20
  @ht16k33_oscillator 0x01
  @ht16k33_cmd_brightness 0xE0

  @empty_buffer List.duplicate(0, 16)

  @doc """
  Create an HT16K33 driver for device on the specified I2C address (defaults to
  0x70) and I2C bus (defaults to platform specific bus).
  """
  def start_link(opts \\ []) do
    bus_name = opts[:bus_name] || @default_bus_name
    address = opts[:address] || @default_address
    name = opts[:name] || __MODULE__

    GenServer.start_link(__MODULE__, {bus_name, address}, name: name)
  end

  def set_blink(server \\ __MODULE__, frequency)
      when frequency in [:blink_off, :blink_2hz, :blink_1hz, :blink_halfhz] do
    mapped_frequency = map_frequency(frequency)
    GenServer.call(server, {:set_blink, mapped_frequency})
  end

  def set_brightness(server \\ __MODULE__, brightness) when brightness in 0..15 do
    GenServer.call(server, {:set_brightness, brightness})
  end

  def set_led(server \\ __MODULE__, led, value) when led in 0..127 and value in 0..1 do
    pos = div(led, 8)
    offset = rem(led, 8)
    GenServer.call(server, {:set_led, pos, offset, value})
  end

  def write_display(server \\ __MODULE__) do
    GenServer.call(server, :write_display)
  end

  def clear(server \\ __MODULE__) do
    GenServer.call(server, :clear)
  end

  @doc false
  def update_buffer(server \\ __MODULE__, pos, fun) do
    GenServer.call(server, {:update_buffer, pos, fun})
  end

  @impl GenServer
  def init({bus_name, address}) do
    case I2C.open(bus_name) do
      {:ok, i2c_bus} ->
        {:ok, %{address: address, buffer: @empty_buffer, i2c_bus: i2c_bus}, {:continue, :begin}}

      error ->
        {:stop, error}
    end
  end

  @impl GenServer
  def handle_continue(:begin, %{address: address, i2c_bus: i2c_bus} = state) do
    I2C.write!(i2c_bus, address, [@ht16k33_system_setup ||| @ht16k33_oscillator])
    {:reply, :ok, state} = handle_call({:set_blink, @ht16k33_blink_off}, nil, state)
    {:reply, :ok, state} = handle_call({:set_brightness, 15}, nil, state)
    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:set_blink, frequency}, _from, %{address: address, i2c_bus: i2c_bus} = state) do
    I2C.write!(i2c_bus, address, [@ht16k33_blink_cmd ||| @ht16k33_blink_displayon ||| frequency])
    {:reply, :ok, state}
  end

  def handle_call(
        {:set_brightness, brightness},
        _from,
        %{address: address, i2c_bus: i2c_bus} = state
      ) do
    I2C.write!(i2c_bus, address, [@ht16k33_cmd_brightness ||| brightness])
    {:reply, :ok, state}
  end

  def handle_call({:set_led, pos, offset, value}, _from, %{buffer: buffer} = state) do
    updated_buffer =
      List.update_at(buffer, pos, fn byte ->
        case value do
          0 -> byte &&& ~~~(1 <<< offset)
          1 -> byte ||| 1 <<< offset
        end
      end)

    {:reply, :ok, %{state | buffer: updated_buffer}}
  end

  def handle_call(
        :write_display,
        _from,
        %{address: address, buffer: buffer, i2c_bus: i2c_bus} = state
      ) do
    for {byte, i} <- Enum.with_index(buffer) do
      I2C.write!(i2c_bus, address, [i, byte])
    end

    {:reply, :ok, state}
  end

  def handle_call(:clear, _from, state) do
    {:reply, :ok, %{state | buffer: @empty_buffer}}
  end

  def handle_call({:update_buffer, pos, fun}, _from, %{buffer: buffer} = state) do
    {:reply, :ok, %{state | buffer: List.update_at(buffer, pos, fun)}}
  end

  defp map_frequency(:blink_off), do: @ht16k33_blink_off
  defp map_frequency(:blink_2hz), do: @ht16k33_blink_2hz
  defp map_frequency(:blink_1hz), do: @ht16k33_blink_1hz
  defp map_frequency(:blink_halfhz), do: @ht16k33_blink_halfhz

  defmacro __using__(_opts) do
    quote do
      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]}
        }
      end

      def start_link(opts \\ []) do
        opts
        |> Keyword.put_new(:name, __MODULE__)
        |> unquote(__MODULE__).start_link()
      end

      def set_blink(server \\ __MODULE__, frequency) do
        unquote(__MODULE__).set_blink(server, frequency)
      end

      def set_brightness(server \\ __MODULE__, brightness) do
        unquote(__MODULE__).set_brightness(server, brightness)
      end

      def set_led(server \\ __MODULE__, led, value) do
        unquote(__MODULE__).set_led(server, led, value)
      end

      def write_display(server \\ __MODULE__) do
        unquote(__MODULE__).write_display(server)
      end

      def clear(server \\ __MODULE__) do
        unquote(__MODULE__).clear(server)
      end
    end
  end
end
