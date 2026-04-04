defmodule Mix.Tasks.Codex.Login do
  @moduledoc """
  Opens a browser for Codex device authentication.

  Usage:
      mix codex.login

  This task:
  1. Requests a device code from Auth0
  2. Opens the verification URL and displays the user code
  3. Polls for authorization (you approve in the browser)
  4. Saves tokens to ~/.musician/auth/codex.yaml
  """
  use Mix.Task

  @shortdoc "Authenticate with Codex via device code flow"

  def run(_args) do
    # Ensure req is started (finch may already be running from umbrella boot)
    Application.ensure_all_started(:req)

    case Finch.start_link(name: Req.Finch) do
      {:ok, finch_pid} -> Process.unlink(finch_pid)
      {:error, {:already_started, finch_pid}} -> Process.unlink(finch_pid)
    end

    IO.puts("==> Requesting Codex device code...")

    case MusicianAuth.CodexDevice.request_device_code() do
      {:ok, code_response} ->
        IO.puts("""

        Open this URL in your browser:
          #{code_response.verification_uri}

        Enter this code: #{code_response.user_code}

        Waiting for authorization... (this task will stay running)
        """)

        poll_for_token(code_response.device_code, code_response.interval)

      {:error, {:api_error, 403, _html}} ->
        IO.puts("""

        [Error] Auth0 blocked the request — bot protection is active.
        This typically means your IP or user-agent is being blocked.
        Try running this command from a different network or browser.
        """)

      {:error, reason} ->
        IO.puts("[Error] Failed to request device code: #{inspect(reason)}")
        System.halt(1)
    end
  end

  defp poll_for_token(device_code, interval) do
    case MusicianAuth.CodexDevice.poll_for_token(device_code, interval: interval) do
      {:ok, tokens} ->
        IO.puts("\n==> Authorization successful! Saving tokens...")

        auth_entry = %{
          "auth_mode" => "device",
          "tokens" => tokens
        }

        case MusicianAuth.TokenStore.write("codex", auth_entry) do
          :ok ->
            IO.puts("Tokens saved to ~/.musician/auth/codex.yaml")
            IO.puts("Codex authentication complete.")

          {:error, reason} ->
            IO.puts("[Error] Failed to save tokens: #{inspect(reason)}")
            System.halt(1)
        end

      {:error, :timeout} ->
        IO.puts("\n[Error] Authorization timed out. Please try again.")
        System.halt(1)

      {:error, :expired} ->
        IO.puts("\n[Error] The device code has expired. Please run `mix codex.login` again.")
        System.halt(1)

      {:error, :denied} ->
        IO.puts("\n[Error] Authorization was denied. Please run `mix codex.login` again.")
        System.halt(1)

      {:error, reason} ->
        IO.puts("\n[Error] Unexpected error during polling: #{inspect(reason)}")
        System.halt(1)
    end
  end
end
