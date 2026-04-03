defmodule MusicianAuth.MixProject do
  use Mix.Project

  def project do
    [
      app: :musician_auth,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def application do
    [extra_applications: [:logger, :crypto]]
  end

  defp deps do
    [
      {:yaml_elixir, "~> 2.9"},
      {:req, "~> 0.5"},
      {:musician_core, in_umbrella: true}
    ]
  end
end
