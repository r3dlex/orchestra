defmodule MusicianMemory.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    db_path = Application.fetch_env!(:musician_memory, :db_path)
    File.mkdir_p!(Path.dirname(db_path))

    children = [
      {MusicianMemory.Sweep, []}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: MusicianMemory.Supervisor)
  end
end
