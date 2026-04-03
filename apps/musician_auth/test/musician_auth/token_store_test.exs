defmodule MusicianAuth.TokenStoreTest do
  use ExUnit.Case, async: false

  alias MusicianAuth.TokenStore

  @test_dir System.tmp_dir!() |> Path.join("musician_auth_test_#{:rand.uniform(100_000)}")
  @test_token_name "test_token_#{:rand.uniform(100_000)}"

  setup do
    File.mkdir_p!(@test_dir)
    :ok
  end

  test "write/2 and read/1 round-trip a token map" do
    path = Path.join(@test_dir, "#{@test_token_name}.yaml")
    yaml = "access_token: tok-abc\nexpires_at: 2026-04-03T13:00:00Z\n"
    File.write!(path, yaml)

    {:ok, content} = File.read(path)
    {:ok, parsed} = YamlElixir.read_from_string(content)
    assert parsed["access_token"] == "tok-abc"
    assert parsed["expires_at"] == "2026-04-03T13:00:00Z"

    File.rm(path)
  end

  test "read/1 returns {:error, :not_found} for missing file" do
    assert {:error, :not_found} = TokenStore.read("nonexistent_token_xyz_#{:rand.uniform(99999)}")
  end

  test "token_path/1 returns path with .yaml extension" do
    path = TokenStore.token_path("codex")
    assert String.ends_with?(path, "codex.yaml")
    assert String.contains?(path, ".musician/auth")
  end
end
