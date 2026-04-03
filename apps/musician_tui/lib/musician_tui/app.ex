defmodule MusicianTui.App do
  @moduledoc "Main Ratatouille application for Musician."

  @behaviour Ratatouille.App

  alias MusicianTui.{Model, Views}

  def init(%{window: _window}) do
    %Model{}
  end

  def update(%Model{} = model, msg) do
    case msg do
      {:event, %{ch: ?\r}} ->
        submit_input(model)

      {:event, %{ch: 127}} ->
        %{model | input: String.slice(model.input, 0..-2//1)}

      {:event, %{ch: ch}} when ch > 0 ->
        %{model | input: model.input <> <<ch::utf8>>}

      # Programmatic input used by tests
      {:input, char} ->
        %{model | input: model.input <> <<char::utf8>>}

      {:set_loading, loading} ->
        %{model | loading: loading}

      {:add_message, role, content} ->
        message = %{role: role, content: content}
        %{model | messages: model.messages ++ [message]}

      {:set_provider, provider} ->
        %{model | provider: provider}

      {:set_model, model_name} ->
        %{model | model: model_name}

      {:update_tokens, count} ->
        %{model | token_count: count}

      _ ->
        model
    end
  end

  def render(%Model{} = model) do
    {
      :view,
      [],
      [
        Views.Conversation.render(model),
        Views.Input.render(model),
        Views.StatusBar.render(model)
      ]
    }
  end

  defp submit_input(%Model{input: ""} = model), do: model

  defp submit_input(%Model{input: input} = model) do
    user_message = %{role: "user", content: input}
    %{model | input: "", messages: model.messages ++ [user_message], loading: true}
  end
end
