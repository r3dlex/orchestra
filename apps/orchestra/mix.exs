defmodule Orchestra.MixProject do
  use Mix.Project

  def project do
    [
      app: :orchestra,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [threshold: 80]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:musician_plugins, in_umbrella: true},
      {:jason, "~> 1.4"}
    ]
  end
end
