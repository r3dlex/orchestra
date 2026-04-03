defmodule Mix.Tasks.Musician.Codex.Login do
  use Mix.Task

  @shortdoc "Authenticate with Codex via device code flow"

  @moduledoc """
  Runs the OpenAI Device Code flow to obtain and persist Codex tokens.

      mix musician.codex.login

  Steps:
  1. Requests a device code from auth0.openai.com
  2. Prints the user_code and verification URL
  3. Polls until the user authorizes (or the code expires)
  4. Saves the resulting tokens to ~/.musician/auth/codex.yaml

  After login, `mix test apps/musician_auth --only codex_e2e` will use
  the stored tokens automatically via TokenStore.read("codex").
  """

  @impl Mix.Task
  def run(_args) do
    Application.ensure_all_started(:req)

    {:ok, finch_pid} = Finch.start_link(name: Req.Finch)
    Process.unlink(finch_pid)

    Mix.shell().info("Requesting Codex device code...")

    case MusicianAuth.CodexDevice.request_device_code() do
      {:ok,
       %{
         user_code: code,
         verification_uri: uri,
         device_code: dc,
         interval: interval,
         expires_in: exp
       }} ->
        Mix.shell().info("""

        ┌─────────────────────────────────────────────────┐
        │  Open this URL in your browser:                 │
        │  #{String.pad_trailing(uri, 47)} │
        │                                                 │
        │  Enter this code:  #{String.pad_trailing(code, 29)} │
        │  Expires in:       #{String.pad_trailing("#{exp}s", 29)} │
        └─────────────────────────────────────────────────┘
        """)

        Mix.shell().info("Waiting for authorization (polling every #{interval}s)...")

        case MusicianAuth.CodexDevice.poll_for_token(dc, interval: interval) do
          {:ok, tokens} ->
            token_map = %{
              "access_token" => tokens.access_token,
              "refresh_token" => tokens.refresh_token,
              "id_token" => tokens.id_token,
              "expires_in" => tokens.expires_in,
              "token_type" => tokens.token_type
            }

            case MusicianAuth.TokenStore.write("codex", token_map) do
              :ok ->
                Mix.shell().info(
                  "Codex login successful. Tokens saved to ~/.musician/auth/codex.yaml"
                )

              {:error, reason} ->
                Mix.raise("Failed to save tokens: #{inspect(reason)}")
            end

          {:error, :timeout} ->
            Mix.raise("Authorization timed out. Run `mix musician.codex.login` again.")

          {:error, :denied} ->
            Mix.raise("Authorization denied by user.")

          {:error, :expired} ->
            Mix.raise("Device code expired. Run `mix musician.codex.login` again.")

          {:error, reason} ->
            Mix.raise("Authorization failed: #{inspect(reason)}")
        end

      {:error, {:api_error, 403, _}} ->
        Mix.raise("""
        auth0.openai.com returned 403 (bot protection).
        This endpoint requires browser-based authorization.
        Run `codex login --device-auth` from a terminal with browser access instead.
        """)

      {:error, reason} ->
        Mix.raise("Failed to request device code: #{inspect(reason)}")
    end
  end
end
