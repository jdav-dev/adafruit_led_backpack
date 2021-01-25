if Code.ensure_loaded?(Phoenix.LiveView) do
  defmodule AdafruitLedBackpack.SevenSegmentLive do
    use Phoenix.HTML
    use Phoenix.LiveView

    import Bitwise
    import Phoenix.LiveView.Helpers

    alias AdafruitLedBackpack.Interface.PubSub

    @default_bus_name "i2c-1"
    @default_address 0x70
    @default_background "#111"
    @default_off "#BBB"
    @default_on "#F00"

    @bitmasks [
      dig1a: {0, 0b00000001},
      dig1b: {0, 0b00000010},
      dig1c: {0, 0b00000100},
      dig1d: {0, 0b00001000},
      dig1e: {0, 0b00010000},
      dig1f: {0, 0b00100000},
      dig1g: {0, 0b01000000},
      dig2a: {2, 0b00000001},
      dig2b: {2, 0b00000010},
      dig2c: {2, 0b00000100},
      dig2d: {2, 0b00001000},
      dig2e: {2, 0b00010000},
      dig2f: {2, 0b00100000},
      dig2g: {2, 0b01000000},
      dig3a: {6, 0b00000001},
      dig3b: {6, 0b00000010},
      dig3c: {6, 0b00000100},
      dig3d: {6, 0b00001000},
      dig3e: {6, 0b00010000},
      dig3f: {6, 0b00100000},
      dig3g: {6, 0b01000000},
      dig4a: {8, 0b00000001},
      dig4b: {8, 0b00000010},
      dig4c: {8, 0b00000100},
      dig4d: {8, 0b00001000},
      dig4e: {8, 0b00010000},
      dig4f: {8, 0b00100000},
      dig4g: {8, 0b01000000},
      d1: {4, 0b00000100},
      d2: {4, 0b00001000},
      d3: {4, 0b00000010},
      d4: {4, 0b00000010},
      d5: {4, 0b00010000}
    ]

    @impl Phoenix.LiveView
    def mount(_params, session, socket) do
      bus_name = Map.get(session, "bus_name", @default_bus_name)
      address = Map.get(session, "address", @default_address)
      background = Map.get(session, "background", @default_background)
      invert = Map.get(session, "invert", false)
      off = Map.get(session, "off", @default_off)
      on = Map.get(session, "on", @default_on)

      registers =
        with true <- connected?(socket),
             {:ok, registers} <- PubSub.subscribe(bus_name, address) do
          registers
        else
          _ -> %{}
        end

      {:ok,
       socket
       |> assign(
         address: address,
         background: background,
         bus_name: bus_name,
         invert: invert,
         off: off,
         on: on
       )
       |> assign_registers(registers)}
    end

    defp assign_registers(socket, registers) do
      Enum.reduce(@bitmasks, socket, fn {assign, {register, bitmask}}, socket ->
        assign(socket, assign, active?(registers, register, bitmask))
      end)
    end

    defp active?(registers, register, bitmask) do
      (Map.get(registers, register, 0) &&& bitmask) == bitmask
    end

    @impl Phoenix.LiveView
    def handle_info({PubSub, @default_bus_name, @default_address, registers}, socket) do
      {:noreply, assign_registers(socket, registers)}
    end

    @impl Phoenix.LiveView
    def render(assigns) do
      ~L"""
      <svg
        viewBox="0 0 120 40.8"
        style="background-color: <%= @background %>;<%= if @invert, do: "transform: rotate(0.5turn);" %>"
        fill="<%= @off %>"
      >
        <g transform="translate(0,-256.2)">
          <path <%= if @dig1a, do: raw(~s[fill="#{@on} "]) %>d="m 19.07341,260.4995 13.378889,6.3e-4 0.722096,0.8785 -2.495033,2.12125 -10.891933,-3.8e-4 -1.746923,-2.1215 z" />
          <path <%= if @dig1b, do: raw(~s[fill="#{@on}" ]) %> d="m 32.05065,274.746 2.13986,-12.13575 -0.724184,-0.878 -2.495078,2.1215 -1.920599,10.89226 1.235519,1.5 z" />
          <path <%= if @dig1c, do: raw(~s[fill="#{@on}" ]) %>d="m 31.396828,278.45401 -2.139858,12.13574 -1.033815,0.878 -1.746923,-2.1215 1.920598,-10.89225 1.7645,-1.5 z" />
          <path <%= if @dig1d, do: raw(~s[fill="#{@on}" ]) %>d="m 13.395591,292.70001 13.379044,-2.5e-4 1.031903,-0.8785 -1.746966,-2.12125 h -10.892 l -2.495078,2.1215 z" />
          <path <%= if @dig1e, do: raw(~s[fill="#{@on}" ]) %>d="m 13.797044,278.45401 -2.140076,12.13574 0.724185,0.878 2.494577,-2.1215 1.921318,-10.89225 -1.23552,-1.5 z" />
          <path <%= if @dig1f, do: raw(~s[fill="#{@on}" ]) %>d="m 14.450867,274.746 2.14011,-12.13575 1.033815,-0.878 1.746423,2.1215 -1.920348,10.89225 -1.7645,1.5 z" />
          <path <%= if @dig1g, do: raw(~s[fill="#{@on}" ]) %>d="m 17.742446,275.10001 10.892002,-10e-6 1.235511,1.49999 -1.764492,1.50001 -10.892002,10e-6 L 15.977957,276.6 Z" />
          <path <%= if @dig2a, do: raw(~s[fill="#{@on}" ]) %>d="m 44.010442,260.49949 13.378889,6.3e-4 0.722096,0.8785 -2.495033,2.12125 -10.891933,-3.7e-4 -1.746923,-2.1215 z" />
          <path <%= if @dig2b, do: raw(~s[fill="#{@on}" ]) %>d="m 56.987682,274.74599 2.13986,-12.13575 -0.724184,-0.878 -2.495078,2.1215 -1.920599,10.89226 1.235519,1.5 z" />
          <path <%= if @dig2c, do: raw(~s[fill="#{@on}" ]) %>d="m 56.33386,278.454 -2.139858,12.13574 -1.033815,0.878 -1.746923,-2.1215 1.920598,-10.89225 1.7645,-1.5 z" />
          <path <%= if @dig2d, do: raw(~s[fill="#{@on}" ]) %>d="m 38.332623,292.7 13.379044,-2.5e-4 1.031903,-0.8785 L 50.996604,289.7 h -10.892 l -2.495078,2.1215 z" />
          <path <%= if @dig2e, do: raw(~s[fill="#{@on}" ]) %>d="m 38.734076,278.454 -2.140076,12.13574 0.724185,0.878 2.494577,-2.1215 1.921318,-10.89225 -1.23552,-1.5 z" />
          <path <%= if @dig2f, do: raw(~s[fill="#{@on}" ]) %>d="m 39.387899,274.74599 2.14011,-12.13575 1.033815,-0.878 1.746423,2.1215 -1.920348,10.89225 -1.7645,1.5 z" />
          <path <%= if @dig2g, do: raw(~s[fill="#{@on}" ]) %>d="m 42.679478,275.1 10.892002,-1e-5 1.235511,1.49999 -1.764492,1.50001 -10.892002,1e-5 -1.235508,-1.50001 z" />
          <path <%= if @dig3a, do: raw(~s[fill="#{@on}" ]) %>d="m 74.611442,260.49949 13.378889,6.3e-4 0.722097,0.8785 -2.495034,2.12125 -10.891932,-3.7e-4 -1.746924,-2.1215 z" />
          <path <%= if @dig3b, do: raw(~s[fill="#{@on}" ]) %>d="m 87.588682,274.74599 2.139856,-12.13575 -0.72418,-0.878 -2.495078,2.1215 -1.920599,10.89226 1.235519,1.5 z" />
          <path <%= if @dig3c, do: raw(~s[fill="#{@on}" ]) %>d="m 86.93486,278.454 -2.139858,12.13574 -1.033815,0.878 -1.746923,-2.1215 1.920598,-10.89225 1.7645,-1.5 z" />
          <path <%= if @dig3d, do: raw(~s[fill="#{@on}" ]) %>d="m 68.933623,292.7 13.379044,-2.5e-4 1.031903,-0.8785 L 81.597604,289.7 h -10.892 l -2.495078,2.1215 z" />
          <path <%= if @dig3e, do: raw(~s[fill="#{@on}" ]) %>d="m 69.335076,278.454 -2.140076,12.13574 0.724185,0.878 2.494577,-2.1215 1.921318,-10.89225 -1.23552,-1.5 z" />
          <path <%= if @dig3f, do: raw(~s[fill="#{@on}" ]) %>d="m 69.988899,274.74599 2.14011,-12.13575 1.033816,-0.878 1.746422,2.1215 -1.920348,10.89225 -1.7645,1.5 z" />
          <path <%= if @dig3g, do: raw(~s[fill="#{@on}" ]) %>d="m 73.280478,275.1 10.892002,-1e-5 1.235511,1.49999 -1.764492,1.50001 -10.892002,1e-5 -1.235508,-1.50001 z" />
          <path <%= if @dig4a, do: raw(~s[fill="#{@on}" ]) %>d="m 99.611442,260.49949 13.378888,6.3e-4 0.7221,0.8785 -2.49504,2.12125 -10.89193,-3.7e-4 -1.746922,-2.1215 z" />
          <path <%= if @dig4b, do: raw(~s[fill="#{@on}" ]) %>d="m 112.58868,274.74599 2.13986,-12.13575 -0.72418,-0.878 -2.49508,2.1215 -1.9206,10.89226 1.23552,1.5 z" />
          <path <%= if @dig4c, do: raw(~s[fill="#{@on}" ]) %>d="m 111.93486,278.454 -2.13986,12.13574 -1.03381,0.878 -1.74693,-2.1215 1.9206,-10.89225 1.7645,-1.5 z" />
          <path <%= if @dig4d, do: raw(~s[fill="#{@on}" ]) %>d="m 93.933623,292.7 13.379047,-2.5e-4 1.0319,-0.8785 L 106.5976,289.7 H 95.705604 l -2.495078,2.1215 z" />
          <path <%= if @dig4e, do: raw(~s[fill="#{@on}" ]) %>d="m 94.335076,278.454 -2.140076,12.13574 0.724185,0.878 2.494577,-2.1215 1.921318,-10.89225 -1.23552,-1.5 z" />
          <path <%= if @dig4f, do: raw(~s[fill="#{@on}" ]) %>d="m 94.988899,274.74599 2.14011,-12.13575 1.033815,-0.878 1.746423,2.1215 -1.920348,10.89225 -1.7645,1.5 z" />
          <path <%= if @dig4g, do: raw(~s[fill="#{@on}" ]) %>d="m 98.280478,275.1 10.892002,-1e-5 1.23551,1.49999 -1.76449,1.50001 -10.892003,1e-5 -1.235508,-1.50001 z" />
          <circle <%= if @d1, do: raw(~s[fill="#{@on}" ]) %>cx="9.1714983" cy="269.29999" r="1.5" />
          <circle <%= if @d2, do: raw(~s[fill="#{@on}" ]) %>cx="6.6475" cy="283.89999" r="1.5" />
          <circle <%= if @d3, do: raw(~s[fill="#{@on}" ]) %>cx="64.7715" cy="269.29999" r="1.5" />
          <circle <%= if @d4, do: raw(~s[fill="#{@on}" ]) %>cx="62.247501" cy="283.89999" r="1.5" />
          <circle <%= if @d5, do: raw(~s[fill="#{@on}" ]) %>cx="93.574501" cy="261.99899" r="1.5" />
        </g>
      </svg>
      """
    end
  end
end
