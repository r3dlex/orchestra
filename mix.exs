defmodule Musician.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.1.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev], runtime: false}
    ]
  end

  defp aliases do
    [
      test: "test --no-start",
      pipeline: ["run -e 'MusicianCli.Mix.Tasks.Pipeline.run([])'"]
    ]
  end
end
