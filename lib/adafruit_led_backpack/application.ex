defmodule AdafruitLedBackpack.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    case Code.ensure_loaded?(Phoenix.PubSub) do
      true ->
        children = [
          {Phoenix.PubSub, name: AdafruitLedBackpack.PubSub}
        ]

        opts = [strategy: :one_for_one, name: AdafruitLedBackpack.Supervisor]
        Supervisor.start_link(children, opts)

      false ->
        :ignore
    end
  end
end
