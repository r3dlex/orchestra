defmodule MusicianCore.Config.Presets do
  @moduledoc """
  Built-in provider presets. These are convenience defaults — users
  can override any field in their config.yaml.
  """

  alias MusicianCore.Config.Schema.ProviderConfig

  @doc "Returns all built-in provider presets."
  @spec all() :: %{String.t() => ProviderConfig.t()}
  def all do
    %{
      "minimax" => %ProviderConfig{
        api_base: "https://api.minimax.chat/v1",
        model: "abab7-chat",
        api_key_env: "MINIMAX_API_KEY"
      },
      "claude" => %ProviderConfig{
        api_base: "https://api.anthropic.com/v1",
        model: "claude-sonnet-4-6",
        api_key_env: "ANTHROPIC_API_KEY",
        native: true
      },
      "codex" => %ProviderConfig{
        api_base: "https://api.openai.com/v1",
        model: "gpt-4.1",
        api_key_env: "OPENAI_API_KEY",
        auth_method: :device
      },
      "gemini" => %ProviderConfig{
        api_base: "https://generativelanguage.googleapis.com/v1beta/openai",
        model: "gemini-2.0-flash",
        api_key_env: "GEMINI_API_KEY"
      },
      "ollama" => %ProviderConfig{
        api_base: "http://localhost:11434/v1",
        model: "llama3",
        api_key_env: nil
      }
    }
  end

  @doc "Returns the preset for a given provider name, or nil."
  @spec get(String.t()) :: ProviderConfig.t() | nil
  def get(name), do: Map.get(all(), name)

  @doc "Returns all preset provider names."
  @spec names() :: [String.t()]
  def names, do: Map.keys(all())
end
