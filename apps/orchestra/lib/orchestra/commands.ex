defmodule Orchestra.Commands do
  @moduledoc "Available Orchestra slash commands."

  def list do
    [
      %{name: "/orchestra team", description: "Spawn N workers on a task"},
      %{name: "/orchestra ralph", description: "Run persistence loop until verified"},
      %{name: "/orchestra status", description: "Show current team and worker status"},
      %{name: "/orchestra stop", description: "Stop all active workers"}
    ]
  end
end
