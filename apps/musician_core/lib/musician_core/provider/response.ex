defmodule MusicianCore.Provider.Response do
  @moduledoc "Completion response struct."

  defstruct [:id, :content, :finish_reason, :usage, tool_calls: []]

  @type usage :: %{
          prompt_tokens: non_neg_integer(),
          completion_tokens: non_neg_integer(),
          total_tokens: non_neg_integer()
        }

  @type t :: %__MODULE__{
          id: String.t() | nil,
          content: String.t() | nil,
          finish_reason: String.t() | nil,
          usage: usage() | nil,
          tool_calls: list(map())
        }

  @doc "Parses an OpenAI-format response body map into a Response struct."
  @spec from_openai(map()) :: t()
  def from_openai(body) when is_map(body) do
    choice = get_in(body, ["choices", Access.at(0)]) || %{}
    message = Map.get(choice, "message", %{})

    %__MODULE__{
      id: Map.get(body, "id"),
      content: Map.get(message, "content"),
      finish_reason: Map.get(choice, "finish_reason"),
      tool_calls: Map.get(message, "tool_calls", []),
      usage: parse_usage(Map.get(body, "usage"))
    }
  end

  defp parse_usage(nil), do: nil

  defp parse_usage(usage) do
    %{
      prompt_tokens: Map.get(usage, "prompt_tokens", 0),
      completion_tokens: Map.get(usage, "completion_tokens", 0),
      total_tokens: Map.get(usage, "total_tokens", 0)
    }
  end
end
