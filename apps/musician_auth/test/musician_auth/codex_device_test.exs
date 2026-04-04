defmodule MusicianAuth.CodexDeviceTest do
  use ExUnit.Case, async: true

  alias MusicianAuth.CodexDevice

  setup do
    bypass = Bypass.open()

    # Start Req's Finch instance so Req.post/2 can make HTTP calls.
    case Finch.start_link(name: Req.Finch) do
      {:ok, pid} ->
        Process.unlink(pid)
        :ok

      {:error, {:already_started, pid}} ->
        Process.unlink(pid)
        :ok
    end

    {:ok, bypass: bypass}
  end

  # --- request_device_code/0 ---

  describe "request_device_code/0" do
    test "returns parsed device code fields on success", %{bypass: bypass} do
      json_body = ~s({
        "device_code": "test-device-code-123",
        "user_code": "USER-ABCD",
        "verification_uri": "https://example.com/verify",
        "expires_in": 300,
        "interval": 5
      })

      Bypass.expect(bypass, "POST", "/oauth/device/code", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, json_body)
      end)

      Application.put_env(
        :musician_auth,
        :device_code_url,
        "http://localhost:#{bypass.port}/oauth/device/code"
      )

      assert {:ok, result} = CodexDevice.request_device_code()
      assert result.device_code == "test-device-code-123"
      assert result.user_code == "USER-ABCD"
      assert result.verification_uri == "https://example.com/verify"
      assert result.expires_in == 300
      assert result.interval == 5
    after
      Application.delete_env(:musician_auth, :device_code_url)
    end

    test "defaults interval to 5 when server returns null interval", %{bypass: bypass} do
      json_body = ~s({
        "device_code": "dc", "user_code": "uc",
        "verification_uri": "https://example.com/verify",
        "expires_in": 300, "interval": null
      })

      Bypass.expect(bypass, "POST", "/oauth/device/code", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, json_body)
      end)

      Application.put_env(
        :musician_auth,
        :device_code_url,
        "http://localhost:#{bypass.port}/oauth/device/code"
      )

      assert {:ok, result} = CodexDevice.request_device_code()
      assert result.interval == 5
    after
      Application.delete_env(:musician_auth, :device_code_url)
    end

    test "returns api_error for non-200 status", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/oauth/device/code", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(429, ~s({"error": "rate_limit"}))
      end)

      Application.put_env(
        :musician_auth,
        :device_code_url,
        "http://localhost:#{bypass.port}/oauth/device/code"
      )

      assert {:error, {:api_error, 429, %{"error" => "rate_limit"}}} =
               CodexDevice.request_device_code()
    after
      Application.delete_env(:musician_auth, :device_code_url)
    end
  end

  # --- exchange_device_code/1 ---

  describe "exchange_device_code/1" do
    test "returns tokens on success", %{bypass: bypass} do
      json_body = ~s({
        "access_token": "access-xyz",
        "refresh_token": "refresh-abc",
        "id_token": "id-token-789",
        "expires_in": 3600,
        "token_type": "Bearer"
      })

      Bypass.expect(bypass, "POST", "/oauth/token", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, json_body)
      end)

      Application.put_env(
        :musician_auth,
        :token_url,
        "http://localhost:#{bypass.port}/oauth/token"
      )

      assert {:ok, tokens} = CodexDevice.exchange_device_code("my-device-code")
      assert tokens.access_token == "access-xyz"
      assert tokens.refresh_token == "refresh-abc"
      assert tokens.id_token == "id-token-789"
      assert tokens.expires_in == 3600
      assert tokens.token_type == "Bearer"
    after
      Application.delete_env(:musician_auth, :token_url)
    end

    test "returns :pending when authorization is still pending", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/oauth/token", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(400, ~s({"error": "authorization_pending"}))
      end)

      Application.put_env(
        :musician_auth,
        :token_url,
        "http://localhost:#{bypass.port}/oauth/token"
      )

      assert {:error, :pending} = CodexDevice.exchange_device_code("any-device-code")
    after
      Application.delete_env(:musician_auth, :token_url)
    end

    test "returns :expired when device code has expired", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/oauth/token", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(400, ~s({"error": "expired_token"}))
      end)

      Application.put_env(
        :musician_auth,
        :token_url,
        "http://localhost:#{bypass.port}/oauth/token"
      )

      assert {:error, :expired} = CodexDevice.exchange_device_code("expired-device-code")
    after
      Application.delete_env(:musician_auth, :token_url)
    end

    test "returns :denied when user denies authorization", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/oauth/token", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(400, ~s({"error": "access_denied"}))
      end)

      Application.put_env(
        :musician_auth,
        :token_url,
        "http://localhost:#{bypass.port}/oauth/token"
      )

      assert {:error, :denied} = CodexDevice.exchange_device_code("any-device-code")
    after
      Application.delete_env(:musician_auth, :token_url)
    end

    test "returns api_error for other non-200/non-400 statuses", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/oauth/token", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(500, ~s({"error": "server_error"}))
      end)

      Application.put_env(
        :musician_auth,
        :token_url,
        "http://localhost:#{bypass.port}/oauth/token"
      )

      assert {:error, {:api_error, 500, %{"error" => "server_error"}}} =
               CodexDevice.exchange_device_code("any-device-code")
    after
      Application.delete_env(:musician_auth, :token_url)
    end
  end

  # --- poll_for_token/1 ---

  describe "poll_for_token/1" do
    test "returns tokens immediately when authorization is already complete", %{bypass: bypass} do
      json_body = ~s({
        "access_token": "poll-access-token",
        "refresh_token": "poll-refresh-token",
        "id_token": "poll-id-token",
        "expires_in": 7200,
        "token_type": "Bearer"
      })

      Bypass.expect(bypass, "POST", "/oauth/token", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(200, json_body)
      end)

      Application.put_env(
        :musician_auth,
        :token_url,
        "http://localhost:#{bypass.port}/oauth/token"
      )

      assert {:ok, tokens} = CodexDevice.poll_for_token("my-device-code", interval: 0)
      assert tokens.access_token == "poll-access-token"
    after
      Application.delete_env(:musician_auth, :token_url)
    end

    test "returns :timeout when max_attempts is reached", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/oauth/token", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(400, ~s({"error": "authorization_pending"}))
      end)

      Application.put_env(
        :musician_auth,
        :token_url,
        "http://localhost:#{bypass.port}/oauth/token"
      )

      # interval: 0 skips sleep; max_attempts: 2 means 2 polls then timeout
      assert {:error, :timeout} =
               CodexDevice.poll_for_token("my-device-code", interval: 0, max_attempts: 2)
    after
      Application.delete_env(:musician_auth, :token_url)
    end

    test "stops polling and returns :expired when device code expires mid-poll", %{bypass: bypass} do
      Bypass.expect(bypass, "POST", "/oauth/token", fn conn ->
        conn
        |> Plug.Conn.put_resp_content_type("application/json")
        |> Plug.Conn.resp(400, ~s({"error": "expired_token"}))
      end)

      Application.put_env(
        :musician_auth,
        :token_url,
        "http://localhost:#{bypass.port}/oauth/token"
      )

      assert {:error, :expired} =
               CodexDevice.poll_for_token("my-device-code", interval: 0, max_attempts: 5)
    after
      Application.delete_env(:musician_auth, :token_url)
    end
  end
end
