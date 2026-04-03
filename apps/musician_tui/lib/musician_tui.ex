defmodule MusicianTui do
  @moduledoc """
  MusicianTui — Ratatouille-based interactive terminal UI for Musician.
  """

  @doc "Starts the TUI application."
  def start do
    # Ratatouille.run requires ex_termbox NIF compiled with Python < 3.12.
    # When available, delegate to the runtime runner.
    apply(Ratatouille, :run, [MusicianTui.App])
  end
end
