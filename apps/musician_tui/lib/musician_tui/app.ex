defmodule MusicianTui.App do
  @moduledoc "Main Ratatouille application for Musician."

  @behaviour Ratatouille.App

  alias MusicianTui.{Model, Views}
  alias MusicianCore.Provider.{Anthropic, OpenAICompat, Request}
  alias MusicianCore.Config.Presets

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

      {:input, char} ->
        %{model | input: model.input <> <<char::utf8>>}

      {:set_loading, loading} ->
        %{model | loading: loading, status: if(loading, do: :loading, else: :idle)}

      {:add_message, role, content} ->
        message = %{role: role, content: content}
        %{model | messages: model.messages ++ [message], loading: false, status: :idle}

      {:streaming_error, reason} ->
        error_msg = %{role: "assistant", content: "[Error: #{inspect(reason)}]"}
        %{model | messages: model.messages ++ [error_msg], loading: false, status: :error}

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

  # Command: /provider <name>
  defp submit_input(%Model{input: "/provider " <> name} = model) do
    name = String.trim(name)
    %{model | input: "", provider: name, status: :idle}
  end

  # Command: /model <name>
  defp submit_input(%Model{input: "/model " <> name} = model) do
    name = String.trim(name)
    %{model | input: "", model: name, status: :idle}
  end

  # Empty submit
  defp submit_input(%Model{input: ""} = model), do: model

  # User message — spawn streaming task and update model to loading state
  defp submit_input(%Model{input: input} = model) do
    user_message = %{role: "user", content: input}

    new_model = %{
      model
      | input: "",
        messages: model.messages ++ [user_message],
        loading: true,
        status: :loading
    }

    spawn_streaming(self(), new_model)
    new_model
  end

  # Start Task to call provider streaming, send result back to TUI pid
  defp spawn_streaming(pid, model) do
    Task.start_link(fn ->
      result = call_provider_streaming(model)

      case result do
        {:ok, content} when is_binary(content) and content != "" ->
          send(pid, {:add_message, "assistant", content})

        {:ok, _} ->
          send(pid, {:add_message, "assistant", "[no response]"})

        {:error, reason} ->
          send(pid, {:streaming_error, reason})
      end
    end)
  end

  defp call_provider_streaming(model) do
    case Presets.get(model.provider) do
      {:ok, config} ->
        request = %Request{
          model: config.model,
          messages: model.messages,
          stream: true
        }

        stream_fun = if config.native, do: &Anthropic.stream/2, else: &OpenAICompat.stream/2

        case stream_fun.(config, request) do
          {:ok, stream} ->
            content = stream |> Enum.to_list() |> Enum.map(&extract_content/1) |> Enum.join("")
            {:ok, content}

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp extract_content(%{"choices" => [%{"delta" => %{"content" => content}}]})
       when is_binary(content), do: content

  defp extract_content(_), do: ""
end
