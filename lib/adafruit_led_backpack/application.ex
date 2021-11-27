defmodule AdafruitLedBackpack.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children =
      case Code.ensure_loaded?(Phoenix.PubSub) do
        true -> [{Phoenix.PubSub, name: AdafruitLedBackpack.PubSub}]
        false -> []
      end

    opts = [strategy: :one_for_one, name: AdafruitLedBackpack.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
