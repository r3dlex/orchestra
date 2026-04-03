defmodule MusicianTui.Views.Conversation do
  @moduledoc "Renders the conversation history panel."

  alias MusicianTui.Model

  @doc "Renders the conversation message list as a tagged tuple tree."
  def render(%Model{messages: messages}) do
    items =
      if messages == [] do
        [{:label, [content: "No messages yet. Start typing below."], []}]
      else
        for msg <- messages do
          role_label = String.upcase(msg.role)
          {:label, [content: "[#{role_label}] #{msg.content}"], []}
        end
      end

    {:panel, [title: "Conversation"], items}
  end
end
