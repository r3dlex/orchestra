defmodule MusicianTui.Views.StatusBar do
  @moduledoc "Renders the status bar showing provider, model, and token count."

  alias MusicianTui.Model

  @doc "Renders a single-line status bar as a tagged tuple tree."
  def render(%Model{provider: provider, model: model, token_count: tokens}) do
    status_text = "Provider: #{provider} | Model: #{model} | Tokens: #{tokens} | Ctrl+C to quit"

    {:bar, [], [{:label, [content: status_text], []}]}
  end
end
