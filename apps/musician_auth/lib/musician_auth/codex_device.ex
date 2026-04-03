defmodule MusicianAuth.CodexDevice do
  @moduledoc """
  Implements OpenAI Device Code flow for Codex authentication.

  Flow:
  1. request_device_code/0 — get a device code + user_code to show the user
  2. User visits verification_uri and enters user_code
  3. poll_for_token/1 — poll until authorized or expired
  4. exchange_device_code/1 — exchange a known device_code for tokens directly
  """

  @token_url "https://auth.openai.com/oauth/token"
  @device_code_url "https://auth.openai.com/oauth/device/code"
  @client_id "app_EMoamEEZ73f0CkXaXp7hrann"

  def request_device_code do
    body = %{
      client_id: @client_id,
      scope: "openid profile email offline_access"
    }

    case Req.post(@device_code_url, json: body) do
      {:ok, %{status: 200, body: resp}} ->
        {:ok, %{
          device_code: resp["device_code"],
          user_code: resp["user_code"],
          verification_uri: resp["verification_uri"],
          expires_in: resp["expires_in"],
          interval: resp["interval"] || 5
        }}

      {:ok, %{status: status, body: body}} ->
        {:error, {:api_error, status, body}}

      {:error, reason} ->
        {:error, {:network, reason}}
    end
  end

  def exchange_device_code(device_code) do
    body = %{
      client_id: @client_id,
      grant_type: "urn:ietf:params:oauth:grant-type:device_code",
      device_code: device_code
    }

    case Req.post(@token_url, json: body) do
      {:ok, %{status: 200, body: resp}} ->
        tokens = %{
          access_token: resp["access_token"],
          refresh_token: resp["refresh_token"],
          id_token: resp["id_token"],
          expires_in: resp["expires_in"],
          token_type: resp["token_type"]
        }
        {:ok, tokens}

      {:ok, %{status: 400, body: %{"error" => "authorization_pending"}}} ->
        {:error, :pending}

      {:ok, %{status: 400, body: %{"error" => "expired_token"}}} ->
        {:error, :expired}

      {:ok, %{status: 400, body: %{"error" => "access_denied"}}} ->
        {:error, :denied}

      {:ok, %{status: status, body: body}} ->
        {:error, {:api_error, status, body}}

      {:error, reason} ->
        {:error, {:network, reason}}
    end
  end

  def poll_for_token(device_code, opts \\ []) do
    interval = Keyword.get(opts, :interval, 5)
    max_attempts = Keyword.get(opts, :max_attempts, 60)
    poll_loop(device_code, interval, max_attempts, 0)
  end

  defp poll_loop(_device_code, _interval, max_attempts, attempt) when attempt >= max_attempts do
    {:error, :timeout}
  end

  defp poll_loop(device_code, interval, max_attempts, attempt) do
    case exchange_device_code(device_code) do
      {:ok, tokens} ->
        {:ok, tokens}

      {:error, :pending} ->
        Process.sleep(interval * 1000)
        poll_loop(device_code, interval, max_attempts, attempt + 1)

      {:error, reason} ->
        {:error, reason}
    end
  end
end
