defmodule AdafruitLedBackpack.Ht16k33 do
  @moduledoc "Driver for interfacing with a Holtek HT16K33 16x8 LED driver."

  use GenServer

  import Bitwise

  @default_interface AdafruitLedBackpack.Interface.I2C
  @default_bus_name "i2c-1"
  @default_address 0x70

  @ht16k33_system_setup 0x20
  @ht16k33_oscillator 0x01

  @setup_data <<@ht16k33_system_setup ||| @ht16k33_oscillator>>

  @ht16k33_blink_cmd 0x80
  @ht16k33_blink_displayon @ht16k33_blink_cmd ||| 0x01
  @ht16k33_blink_off <<@ht16k33_blink_displayon ||| 0x00>>
  @ht16k33_blink_2hz <<@ht16k33_blink_displayon ||| 0x02>>
  @ht16k33_blink_1hz <<@ht16k33_blink_displayon ||| 0x04>>
  @ht16k33_blink_halfhz <<@ht16k33_blink_displayon ||| 0x06>>

  @ht16k33_cmd_brightness 0xE0

  @empty_buffer [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

  @doc """
  Create an HT16K33 driver for device on the specified address (defaults to
  0x#{Integer.to_string(@default_address, 16)}) and bus (defaults to
  #{inspect(@default_bus_name)}).

  Initialize driver with LEDs enabled and all turned off.
  """
  def start_link(opts \\ []) do
    interface = opts[:interface] || @default_interface
    bus_name = opts[:bus_name] || @default_bus_name
    address = opts[:address] || @default_address
    name = opts[:name] || __MODULE__

    GenServer.start_link(__MODULE__, {interface, bus_name, address}, name: name)
  end

  @frequencies [:blink_off, :blink_2hz, :blink_1hz, :blink_halfhz]

  @doc """
  Blink display at specified frequency.

  Frequency must be one of: #{@frequencies |> Enum.map(&"`:#{&1}`") |> Enum.join(", ")}.
  """
  def set_blink(server \\ __MODULE__, frequency) when frequency in @frequencies do
    mapped_frequency = map_frequency(frequency)
    GenServer.call(server, {:set_blink, mapped_frequency})
  end

  defp map_frequency(:blink_off), do: @ht16k33_blink_off
  defp map_frequency(:blink_2hz), do: @ht16k33_blink_2hz
  defp map_frequency(:blink_1hz), do: @ht16k33_blink_1hz
  defp map_frequency(:blink_halfhz), do: @ht16k33_blink_halfhz

  @doc """
  Set brightness of entire display to specified value (16 levels, from 0 to 15).
  """
  def set_brightness(server \\ __MODULE__, brightness) when brightness in 0..15 do
    GenServer.call(server, {:set_brightness, brightness})
  end

  @doc """
  Sets specified LED (value of 0 to 127) to the specified value, `:off` or `:on`.
  """
  def set_led(server \\ __MODULE__, led, value) when led in 0..127 and value in [:off, :on] do
    pos = div(led, 8)
    offset = rem(led, 8)
    GenServer.call(server, {:set_led, pos, offset, value})
  end

  @doc """
  Write display buffer to display interface.
  """
  def write_display(server \\ __MODULE__) do
    GenServer.call(server, :write_display)
  end

  @doc """
  Clear contents of display buffer.
  """
  def clear(server \\ __MODULE__) do
    GenServer.call(server, :clear)
  end

  @doc false
  def update_buffer(server \\ __MODULE__, pos, fun) do
    GenServer.call(server, {:update_buffer, pos, fun})
  end

  @impl GenServer
  def init({interface, bus_name, address}) do
    case interface.open(bus_name) do
      {:ok, bus} ->
        {:ok, %{address: address, buffer: @empty_buffer, bus: bus, interface: interface},
         {:continue, :begin}}

      error ->
        {:stop, error}
    end
  end

  @impl GenServer
  def handle_continue(:begin, state) do
    write_setup!(state)
    write_blink!(@ht16k33_blink_off, state)
    write_brightness!(15, state)
    {:noreply, state}
  end

  defp write_setup!(%{address: address, bus: bus, interface: interface}) do
    interface.write!(bus, address, @setup_data)
  end

  defp write_blink!(frequency, %{address: address, bus: bus, interface: interface}) do
    interface.write!(bus, address, [frequency])
  end

  defp write_brightness!(brightness, %{address: address, bus: bus, interface: interface}) do
    data = brightness_data(brightness)
    interface.write!(bus, address, data)
  end

  for brightness <- 0..15 do
    defp brightness_data(unquote(brightness)) do
      unquote(<<@ht16k33_cmd_brightness ||| brightness>>)
    end
  end

  @impl GenServer
  def handle_call({:set_blink, frequency}, _from, state) do
    write_blink!(frequency, state)
    {:reply, :ok, state}
  end

  def handle_call({:set_brightness, brightness}, _from, state) do
    write_brightness!(brightness, state)
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
        %{address: address, buffer: buffer, bus: bus, interface: interface} = state
      ) do
    for {byte, i} <- Enum.with_index(buffer) do
      interface.write!(bus, address, <<i, byte>>)
    end

    {:reply, :ok, state}
  end

  def handle_call(:clear, _from, state) do
    {:reply, :ok, %{state | buffer: @empty_buffer}}
  end

  def handle_call({:update_buffer, pos, fun}, _from, %{buffer: buffer} = state) do
    {:reply, :ok, %{state | buffer: List.update_at(buffer, pos, fun)}}
  end

  defmacro __using__(_opts) do
    quote do
      @doc """
      Returns a specification to start this module under a supervisor.

      See `Supervisor`.
      """
      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, [opts]}
        }
      end

      @doc delegate_to: {unquote(__MODULE__), :start_link, 1}
      def start_link(opts \\ []) do
        opts
        |> Keyword.put_new(:name, __MODULE__)
        |> unquote(__MODULE__).start_link()
      end

      @doc delegate_to: {unquote(__MODULE__), :set_blink, 2}
      def set_blink(server \\ __MODULE__, frequency) do
        unquote(__MODULE__).set_blink(server, frequency)
      end

      @doc delegate_to: {unquote(__MODULE__), :set_brightness, 2}
      def set_brightness(server \\ __MODULE__, brightness) do
        unquote(__MODULE__).set_brightness(server, brightness)
      end

      @doc delegate_to: {unquote(__MODULE__), :set_led, 3}
      def set_led(server \\ __MODULE__, led, value) do
        unquote(__MODULE__).set_led(server, led, value)
      end

      @doc delegate_to: {unquote(__MODULE__), :write_display, 1}
      def write_display(server \\ __MODULE__) do
        unquote(__MODULE__).write_display(server)
      end

      @doc delegate_to: {unquote(__MODULE__), :clear, 1}
      def clear(server \\ __MODULE__) do
        unquote(__MODULE__).clear(server)
      end
    end
  end
end
