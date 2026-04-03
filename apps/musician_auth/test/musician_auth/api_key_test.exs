defmodule MusicianAuth.ApiKeyTest do
  use ExUnit.Case, async: true

  alias MusicianAuth.ApiKey

  describe "resolve/1" do
    test "reads from env var when config specifies 'env:VAR_NAME'" do
      System.put_env("TEST_MUSICIAN_KEY_123", "sk-test-value")
      assert {:ok, "sk-test-value"} = ApiKey.resolve("env:TEST_MUSICIAN_KEY_123")
    after
      System.delete_env("TEST_MUSICIAN_KEY_123")
    end

    test "returns {:error, :missing} when env var is not set" do
      System.delete_env("UNSET_MUSICIAN_KEY_XYZ")
      assert {:error, :missing} = ApiKey.resolve("env:UNSET_MUSICIAN_KEY_XYZ")
    end

    test "returns inline value when config has direct string key" do
      assert {:ok, "sk-inline-key"} = ApiKey.resolve("sk-inline-key")
    end

    test "returns {:error, :missing} for nil" do
      assert {:error, :missing} = ApiKey.resolve(nil)
    end

    test "returns {:error, :missing} for empty env var" do
      System.put_env("EMPTY_MUSICIAN_KEY", "")
      assert {:error, :missing} = ApiKey.resolve("env:EMPTY_MUSICIAN_KEY")
    after
      System.delete_env("EMPTY_MUSICIAN_KEY")
    end
  end
end
