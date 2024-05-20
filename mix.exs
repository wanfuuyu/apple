defmodule Apple.MixProject do
  use Mix.Project

  @description "Rabbitmq integration with livebook"

  def project do
    [
      app: :apple,
      name: "Apple",
      description: @description,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      mod: {Apple.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:kino, "~> 0.12.0"},
      {:kino_db, "~> 0.2.7"},
      {:testcontainers, "~> 1.8"},
      {:amqp, "~> 3.0"},
      {:kino_vega_lite, "~> 0.1.11"},
      {:httpoison, "~> 2.0"},
      {:poison, "~> 5.0"},
      {:jason, "~> 1.2"},
      {:exqlite, "~> 0.11"},
      {:vega_lite, "~> 0.1.9"}
    ]
  end
end
