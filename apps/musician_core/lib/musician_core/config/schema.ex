defmodule MusicianCore.Config.Schema do
  @moduledoc """
  Configuration struct definitions for Musician.
  """

  defmodule ProviderConfig do
    @moduledoc "Configuration for a single provider."
    @enforce_keys [:api_base, :model]
    defstruct [
      :api_base,
      :model,
      :api_key_env,
      native: false,
      auth_method: :api_key
    ]

    @type t :: %__MODULE__{
            api_base: String.t(),
            model: String.t(),
            api_key_env: String.t() | nil,
            native: boolean(),
            auth_method: :api_key | :device
          }
  end

  defmodule MemoryConfig do
    @moduledoc "Memory system configuration."
    defstruct enabled: true,
              db_path: "~/.musician/memory.db",
              nudge_interval_minutes: 30

    @type t :: %__MODULE__{
            enabled: boolean(),
            db_path: String.t(),
            nudge_interval_minutes: non_neg_integer()
          }
  end

  defmodule SkillsConfig do
    @moduledoc "Skills engine configuration."
    defstruct directory: "~/.musician/skills/",
              auto_create: true,
              self_improve: true

    @type t :: %__MODULE__{
            directory: String.t(),
            auto_create: boolean(),
            self_improve: boolean()
          }
  end

  defmodule SessionConfig do
    @moduledoc "Session history configuration."
    defstruct history_file: "~/.musician/history.jsonl",
              max_entries: 500

    @type t :: %__MODULE__{
            history_file: String.t(),
            max_entries: pos_integer()
          }
  end

  defmodule TuiConfig do
    @moduledoc "TUI configuration."
    defstruct theme: "default",
              vim_mode: false,
              show_token_count: true

    @type t :: %__MODULE__{
            theme: String.t(),
            vim_mode: boolean(),
            show_token_count: boolean()
          }
  end

  defstruct default_provider: "minimax",
            providers: %{},
            memory: nil,
            skills: nil,
            session: nil,
            tui: nil,
            plugins: %{}

  @type t :: %__MODULE__{
          default_provider: String.t(),
          providers: %{String.t() => ProviderConfig.t()},
          memory: MemoryConfig.t(),
          skills: SkillsConfig.t(),
          session: SessionConfig.t(),
          tui: TuiConfig.t(),
          plugins: map()
        }
end
