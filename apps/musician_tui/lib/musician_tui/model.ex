defmodule MusicianTui.Model do
  @moduledoc "Application state for the Musician TUI."

  defstruct [
    # Conversation messages: list of %{role: string, content: string}
    messages: [],
    # Current input buffer
    input: "",
    # Provider name
    provider: "minimax",
    # Model name
    model: "abab6.5s-chat",
    # Token count for current session
    token_count: 0,
    # Whether the app is waiting for a response
    loading: false,
    # Status message shown in status bar
    status: :idle,
    # Command palette open?
    palette_open: false
  ]

  @type message :: %{role: String.t(), content: String.t()}

  @type status :: :idle | :loading | :error

  @type t :: %__MODULE__{
          messages: list(message()),
          input: String.t(),
          provider: String.t(),
          model: String.t(),
          token_count: non_neg_integer(),
          loading: boolean(),
          status: status(),
          palette_open: boolean()
        }
end
