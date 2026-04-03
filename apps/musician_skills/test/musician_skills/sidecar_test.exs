defmodule MusicianSkills.SidecarTest do
  use ExUnit.Case, async: true

  alias MusicianSkills.Sidecar

  @tmp_dir System.tmp_dir!() |> Path.join("musician_sidecar_test_#{:rand.uniform(100_000)}")

  setup do
    File.mkdir_p!(@tmp_dir)
    on_exit(fn -> File.rm_rf(@tmp_dir) end)
    :ok
  end

  test "read/1 parses a .musician.yaml file" do
    path = Path.join(@tmp_dir, ".musician.yaml")
    File.write!(path, "status: active\nimproved_count: 3\n")
    assert {:ok, data} = Sidecar.read(path)
    assert data["status"] == "active"
    assert data["improved_count"] == 3
  end

  test "read/1 returns {:error, :not_found} for missing file" do
    assert {:error, :not_found} = Sidecar.read(Path.join(@tmp_dir, "missing.yaml"))
  end

  test "write/2 writes a .musician.yaml file" do
    path = Path.join(@tmp_dir, ".musician.yaml")
    data = %{"status" => "active", "improved_count" => 1}
    assert :ok = Sidecar.write(path, data)
    assert File.exists?(path)
    {:ok, read_back} = Sidecar.read(path)
    assert read_back["status"] == "active"
  end
end
