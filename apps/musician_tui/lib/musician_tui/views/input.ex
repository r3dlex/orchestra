defmodule MusicianTui.Views.Input do
  @moduledoc "Renders the input box."

  alias MusicianTui.Model

  @doc "Renders the input panel with the current buffer as a tagged tuple tree."
  def render(%Model{input: input, loading: loading}) do
    title = if loading, do: "Input (waiting...)", else: "Input (Enter to send)"

    {:panel, [title: title], [{:label, [content: "> #{input}"], []}]}
  end
end
