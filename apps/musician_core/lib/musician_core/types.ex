defmodule MusicianCore.Types do
  @moduledoc "Shared types for Musician."

  @type role :: :system | :user | :assistant | :tool

  @type message :: %{
          required(:role) => role(),
          required(:content) => String.t() | list(map()),
          optional(:tool_calls) => list(map()),
          optional(:tool_call_id) => String.t(),
          optional(:name) => String.t()
        }

  @type tool :: %{
          required(:type) => String.t(),
          required(:function) => %{
            required(:name) => String.t(),
            required(:description) => String.t(),
            required(:parameters) => map()
          }
        }
end
