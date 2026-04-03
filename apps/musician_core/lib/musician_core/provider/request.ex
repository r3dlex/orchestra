defmodule MusicianCore.Provider.Request do
  @moduledoc "Completion request struct."

  @enforce_keys [:model, :messages]
  defstruct [
    :model,
    :messages,
    tools: [],
    stream: false,
    temperature: 1.0,
    max_tokens: nil,
    system: nil
  ]

  @type t :: %__MODULE__{
          model: String.t(),
          messages: list(MusicianCore.Types.message()),
          tools: list(MusicianCore.Types.tool()),
          stream: boolean(),
          temperature: float(),
          max_tokens: pos_integer() | nil,
          system: String.t() | nil
        }

  @doc "Converts the request struct to a plain map for JSON encoding."
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = req) do
    base = %{
      "model" => req.model,
      "messages" => req.messages,
      "stream" => req.stream,
      "temperature" => req.temperature
    }

    base
    |> maybe_put("tools", req.tools, &(&1 != []))
    |> maybe_put("max_tokens", req.max_tokens, &(&1 != nil))
  end

  defp maybe_put(map, key, value, condition) do
    if condition.(value), do: Map.put(map, key, value), else: map
  end
end
