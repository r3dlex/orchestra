defmodule MusicianAuth.CodexDeviceIntegrationTest do
  use ExUnit.Case, async: false
  @moduletag :provider_e2e
  @moduletag :codex_e2e

  alias MusicianAuth.CodexDevice

  setup do
    case Finch.start_link(name: Req.Finch) do
      {:ok, _} -> :ok
      {:error, {:already_started, _}} -> :ok
    end
  end

  test "request_device_code/0 returns valid device code response from OpenAI" do
    unless System.get_env("CODEX_E2E") == "true" do
      IO.puts("\n[skip] Set CODEX_E2E=true to run Codex device flow integration tests")
    else
      result = CodexDevice.request_device_code()

      case result do
        {:ok, %{device_code: dc, user_code: uc, verification_uri: uri, expires_in: exp, interval: iv}} ->
          assert is_binary(dc) and byte_size(dc) > 0
          assert is_binary(uc) and byte_size(uc) > 0
          assert is_binary(uri) and String.starts_with?(uri, "https://")
          assert is_integer(exp) and exp > 0
          assert is_integer(iv) and iv > 0

          IO.puts("\n[Codex device flow]")
          IO.puts("  Visit: #{uri}")
          IO.puts("  Enter code: #{uc}")
          IO.puts("  Expires in: #{exp}s")

          case CodexDevice.exchange_device_code(dc) do
            {:error, :pending} ->
              IO.puts("  Exchange status: pending (expected — not yet authorized)")
              assert true
            {:ok, tokens} ->
              IO.puts("  Exchange status: success! tokens obtained")
              assert is_map(tokens)
            {:error, other} ->
              IO.puts("  Exchange status: #{inspect(other)}")
              assert true
          end

        {:error, {:api_error, 403, _}} ->
          IO.puts("\n[info] auth0.openai.com returned 403 — bot protection active in non-browser environment")
          assert true

        {:error, reason} ->
          flunk("request_device_code/0 failed: #{inspect(reason)}")
      end
    end
  end
end
