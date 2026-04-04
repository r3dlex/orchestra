defmodule MusicianCli.MixProject do
  use Mix.Project

  def project do
    [
      app: :musician_cli,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases(),
      test_coverage: [threshold: 50]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {MusicianCli.Application, []}
    ]
  end

  defp deps do
    [
      {:burrito, "~> 1.0"},
      {:musician_core, in_umbrella: true},
      {:musician_auth, in_umbrella: true},
      {:musician_tools, in_umbrella: true},
      {:musician_plugins, in_umbrella: true},
      {:bypass, "~> 2.1", only: :test},
      {:meck, "~> 0.9", only: :test}
    ]
  end

  defp releases do
    [
      musician: [
        steps: [:assemble, &Burrito.wrap/1],
        burrito: [
          targets: [
            linux: [os: :linux, cpu: :x86_64],
            macos_intel: [os: :darwin, cpu: :x86_64],
            macos_arm: [os: :darwin, cpu: :aarch64]
          ]
        ]
      ]
    ]
  end
end
