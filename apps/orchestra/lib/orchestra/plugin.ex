defmodule Orchestra.Plugin do
  @moduledoc "Orchestra plugin — implements MusicianPlugins.Api."

  @behaviour MusicianPlugins.Api

  @impl true
  def on_load(_config), do: :ok

  @impl true
  def on_command("/orchestra " <> _subcommand, _args), do: :handled
  def on_command(_command, _args), do: :passthrough

  @impl true
  def on_message(_message), do: :passthrough
end
