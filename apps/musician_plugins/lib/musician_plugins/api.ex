defmodule MusicianPlugins.Api do
  @moduledoc "Behaviour that all Musician plugins must implement."

  @callback on_load(config :: map()) :: :ok | {:error, term()}
  @callback on_command(command :: String.t(), args :: map()) ::
              :ok | {:handled, term()} | :passthrough
  @callback on_message(message :: map()) :: :ok | {:handled, term()} | :passthrough
end
