defmodule MusicianCore.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children =
      if Mix.env() == :test do
        # Mox 1.2.0 requires NimbleOwnership to be running in test mode
        [NimbleOwnership]
      else
        []
      end

    Supervisor.start_link(children, strategy: :one_for_one, name: MusicianCore.Supervisor)
  end
end
