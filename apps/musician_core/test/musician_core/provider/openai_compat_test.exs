defmodule MusicianCore.Provider.OpenAICompatTest do
  use ExUnit.Case, async: true

  alias MusicianCore.Config.Schema.ProviderConfig
  alias MusicianCore.Provider.{OpenAICompat, Request}

  setup do
    Mox.set_mox_from_context([])
    Mox.stub_with(MusicianCore.TokenStoreMock, MusicianCore.TokenStore)
    System.put_env("MINIMAX_API_KEY", "test-minimax-key-123")
    Application.put_env(:musician_core, :http_client, MusicianCore.HTTPMock)
    Application.put_env(:musician_core, :token_store, MusicianCore.TokenStoreMock)
    # Non-device tests: stub TokenStore to return :not_found so headers are empty
    Mox.stub(MusicianCore.TokenStoreMock, :read, fn _ -> {:error, :not_found} end)

    on_exit(fn ->
      System.delete_env("MINIMAX_API_KEY")
      Application.put_env(:musician_core, :http_client, MusicianCore.HTTP)
      Application.put_env(:musician_core, :token_store, MusicianCore.TokenStore)
    end)

    :ok
  end

  # ---------------------------------------------------------------------------
  # build_headers/1 — exercised via complete/2 with a mocked HTTP client
  # ---------------------------------------------------------------------------

  describe "build_headers/1 (via complete/2)" do
    test "with nil api_key_env sends no authorization header" do
      config = %ProviderConfig{
        api_base: "https://api.minimaxi.chat",
        model: "test-model",
        api_key_env: nil
      }

      Mox.expect(MusicianCore.HTTPMock, :post, fn url, _body, headers ->
        assert url == "https://api.minimaxi.chat/chat/completions"
        assert Enum.all?(headers, fn {k, _} -> k != "authorization" end)

        {:ok,
         %{
           status: 200,
           body: %{"choices" => [%{"message" => %{"role" => "assistant", "content" => "ok"}}]}
         }}
      end)

      assert {:ok, _} = OpenAICompat.complete(config, %Request{model: "test-model", messages: []})
    end

    test "with api_key_env set to env var resolves the key from the environment" do
      config = %ProviderConfig{
        api_base: "https://api.minimaxi.chat",
        model: "test-model",
        api_key_env: "env:MINIMAX_API_KEY"
      }

      Mox.expect(MusicianCore.HTTPMock, :post, fn _url, _body, headers ->
        assert {"authorization", "Bearer test-minimax-key-123"} in headers

        {:ok,
         %{
           status: 200,
           body: %{"choices" => [%{"message" => %{"role" => "assistant", "content" => "ok"}}]}
         }}
      end)

      assert {:ok, _} = OpenAICompat.complete(config, %Request{model: "test-model", messages: []})
    end

    test "with api_key_env set to unset env var uses unauthorized placeholder" do
      config = %ProviderConfig{
        api_base: "https://api.minimaxi.chat",
        model: "test-model",
        api_key_env: "env:COMPLETELY_UNSET_VAR_ZXCVBN"
      }

      Mox.expect(MusicianCore.HTTPMock, :post, fn _url, _body, headers ->
        assert {"authorization", "Bearer unauthorized"} in headers

        {:ok,
         %{
           status: 200,
           body: %{"choices" => [%{"message" => %{"role" => "assistant", "content" => "ok"}}]}
         }}
      end)

      assert {:ok, _} = OpenAICompat.complete(config, %Request{model: "test-model", messages: []})
    end

    test "with auth_method: :device and TokenStore.read succeeds uses access_token" do
      config = %ProviderConfig{
        api_base: "https://api.minimaxi.chat",
        model: "test-model",
        auth_method: :device
      }

      Mox.expect(MusicianCore.HTTPMock, :post, fn _url, _body, headers ->
        assert {"authorization", "Bearer codex-token-abc"} in headers

        {:ok,
         %{
           status: 200,
           body: %{"choices" => [%{"message" => %{"role" => "assistant", "content" => "ok"}}]}
         }}
      end)

      Mox.expect(MusicianCore.TokenStoreMock, :read, fn "codex" ->
        {:ok, %{"access_token" => "codex-token-abc", "refresh_token" => "refresh"}}
      end)

      assert {:ok, _} = OpenAICompat.complete(config, %Request{model: "test-model", messages: []})
    end

    test "with auth_method: :device and TokenStore.read fails sends empty headers" do
      config = %ProviderConfig{
        api_base: "https://api.minimaxi.chat",
        model: "test-model",
        auth_method: :device
      }

      Mox.expect(MusicianCore.HTTPMock, :post, fn _url, _body, headers ->
        assert headers == []

        {:ok,
         %{
           status: 200,
           body: %{"choices" => [%{"message" => %{"role" => "assistant", "content" => "ok"}}]}
         }}
      end)

      Mox.expect(MusicianCore.TokenStoreMock, :read, fn "codex" -> {:error, :not_found} end)

      assert {:ok, _} = OpenAICompat.complete(config, %Request{model: "test-model", messages: []})
    end
  end

  # ---------------------------------------------------------------------------
  # complete/2 — error handling
  # ---------------------------------------------------------------------------

  describe "complete/2 error handling" do
    setup do
      config = %ProviderConfig{
        api_base: "https://api.minimaxi.chat",
        model: "test-model",
        api_key_env: nil
      }

      %{config: config, request: %Request{model: "test-model", messages: []}}
    end

    test "returns {:error, :unauthorized} on 401", %{config: config, request: request} do
      Mox.expect(MusicianCore.HTTPMock, :post, fn _, _, _ -> {:ok, %{status: 401}} end)
      assert OpenAICompat.complete(config, request) == {:error, :unauthorized}
    end

    test "returns {:error, {:rate_limited, 30}} on 429 with retry-after header", %{
      config: config,
      request: request
    } do
      Mox.expect(MusicianCore.HTTPMock, :post, fn _, _, _ ->
        {:ok, %{status: 429, headers: [{"retry-after", "30"}]}}
      end)

      assert OpenAICompat.complete(config, request) == {:error, {:rate_limited, 30}}
    end

    test "returns {:error, {:rate_limited, 60}} on 429 without retry-after header", %{
      config: config,
      request: request
    } do
      Mox.expect(MusicianCore.HTTPMock, :post, fn _, _, _ ->
        {:ok, %{status: 429, headers: []}}
      end)

      assert OpenAICompat.complete(config, request) == {:error, {:rate_limited, 60}}
    end

    test "returns {:error, {:api_error, 500, body}} on non-200/401/429 status", %{
      config: config,
      request: request
    } do
      Mox.expect(MusicianCore.HTTPMock, :post, fn _, _, _ ->
        {:ok, %{status: 500, body: %{"error" => %{"message" => "internal error"}}}}
      end)

      assert OpenAICompat.complete(config, request) ==
               {:error, {:api_error, 500, %{"error" => %{"message" => "internal error"}}}}
    end

    test "returns {:error, {:network, reason}} on request error", %{
      config: config,
      request: request
    } do
      Mox.expect(MusicianCore.HTTPMock, :post, fn _, _, _ -> {:error, :econnrefused} end)
      assert OpenAICompat.complete(config, request) == {:error, {:network, :econnrefused}}
    end
  end

  # ---------------------------------------------------------------------------
  # name/0 and supports_tools?/0
  # ---------------------------------------------------------------------------

  test "name/0 returns openai_compat" do
    assert OpenAICompat.name() == "openai_compat"
  end

  test "supports_tools?/0 returns true" do
    assert OpenAICompat.supports_tools?() == true
  end
end
