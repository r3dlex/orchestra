defmodule MusicianAuth.TokenStoreTest do
  use ExUnit.Case, async: true

  alias MusicianAuth.TokenStore

  @test_dir System.tmp_dir!()
            |> Path.join("musician_auth_token_store_#{:rand.uniform(999_999_999)}")

  setup do
    File.mkdir_p!(@test_dir)
    on_exit(fn -> File.rm_rf!(@test_dir) end)
    :ok
  end

  # Helper: path to a token file in the test directory.
  defp path(name), do: Path.join(@test_dir, "#{name}.yaml")

  # --- write/2 ---

  describe "write/2" do
    test "creates the auth directory and writes a YAML file" do
      name = "write_test_#{:rand.uniform(999_999)}"

      assert :ok =
               TokenStore.write(
                 name,
                 %{
                   "access_token" => "tok-abc",
                   "refresh_token" => "ref-xyz"
                 },
                 dir: @test_dir
               )

      assert File.exists?(path(name))

      {:ok, content} = File.read(path(name))
      assert content =~ "access_token: tok-abc"
      assert content =~ "refresh_token: ref-xyz"
    end

    test "writes nested maps as indented YAML" do
      name = "nested_write_#{:rand.uniform(999_999)}"
      assert :ok = TokenStore.write(name, %{"tokens" => %{"access" => "secret"}}, dir: @test_dir)

      {:ok, content} = File.read(path(name))
      assert content =~ "tokens:"
      assert content =~ "  access: secret"
    end

    test "writes nil values as null" do
      name = "nil_write_#{:rand.uniform(999_999)}"
      assert :ok = TokenStore.write(name, %{"field" => nil}, dir: @test_dir)

      {:ok, content} = File.read(path(name))
      assert content =~ "field: null"
    end
  end

  # --- read/1 ---

  describe "read/1" do
    test "returns {:ok, map()} for a valid YAML file" do
      name = "readable_#{:rand.uniform(999_999)}"
      File.write!(path(name), "access_token: tok-read\nrefresh_token: ref-read\n")

      assert {:ok, parsed} = TokenStore.read(name, dir: @test_dir)
      assert parsed["access_token"] == "tok-read"
      assert parsed["refresh_token"] == "ref-read"
    end

    test "returns {:ok, map()} for a file with nested YAML" do
      name = "nested_read_#{:rand.uniform(999_999)}"

      File.write!(path(name), """
      auth_mode: device
      tokens:
        access_token: nested-access
        refresh_token: nested-refresh
      """)

      assert {:ok, parsed} = TokenStore.read(name, dir: @test_dir)
      assert parsed["auth_mode"] == "device"
      assert is_map(parsed["tokens"])
      assert parsed["tokens"]["access_token"] == "nested-access"
    end

    test "returns {:error, :not_found} for a missing file" do
      assert {:error, :not_found} =
               TokenStore.read("nonexistent_token_xyz_#{:rand.uniform(999_999)}", dir: @test_dir)
    end

    test "returns {:error, :parse_error} for invalid YAML" do
      name = "invalid_yaml_#{:rand.uniform(999_999)}"
      File.write!(path(name), "[invalid]")

      assert {:error, :parse_error} = TokenStore.read(name, dir: @test_dir)
    end
  end

  # --- round-trip ---

  describe "write/2 and read/1 round-trip" do
    test "a flat token map survives write then read" do
      name = "round_trip_#{:rand.uniform(999_999)}"
      original = %{"access_token" => "tok-rt", "refresh_token" => "ref-rt", "expires_in" => 3600}

      assert :ok = TokenStore.write(name, original, dir: @test_dir)
      assert {:ok, read_back} = TokenStore.read(name, dir: @test_dir)

      assert read_back["access_token"] == original["access_token"]
      assert read_back["refresh_token"] == original["refresh_token"]
      assert read_back["expires_in"] == original["expires_in"]
    end

    test "a nested token map survives write then read" do
      name = "round_trip_nested_#{:rand.uniform(999_999)}"

      original = %{
        "auth_mode" => "device",
        "tokens" => %{"access_token" => "acc", "id_token" => "idt"}
      }

      assert :ok = TokenStore.write(name, original, dir: @test_dir)
      assert {:ok, read_back} = TokenStore.read(name, dir: @test_dir)

      assert read_back["auth_mode"] == "device"
      assert read_back["tokens"]["access_token"] == "acc"
      assert read_back["tokens"]["id_token"] == "idt"
    end
  end

  # --- token_path/1 ---

  describe "token_path/1" do
    test "returns path with .yaml extension" do
      path = TokenStore.token_path("codex")
      assert String.ends_with?(path, "codex.yaml")
      assert String.contains?(path, ".musician/auth")
    end
  end
end
