defmodule AdafruitLedBackpack.MixProject do
  use Mix.Project

  def project do
    [
      app: :adafruit_led_backpack,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {AdafruitLedBackpack.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:circuits_i2c, "~> 0.3.0", optional: true},
      {:ex_doc, "~> 0.23.0", only: :dev, runtime: false},
      {:phoenix_live_view, "~> 0.15.0", optional: true},
      {:phoenix_pubsub, "~> 2.0", optional: true}
    ]
  end
end
