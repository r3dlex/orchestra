defmodule MusicianTools.FileWriteTest do
  use ExUnit.Case, async: true
  alias MusicianTools.FileWrite

  @tmp_file System.tmp_dir!() |> Path.join("musician_tools_write_#{:rand.uniform(100_000)}.txt")

  setup do
    on_exit(fn -> File.rm(@tmp_file) end)
    :ok
  end

  test "name/0 returns file_write" do
    assert FileWrite.name() == "file_write"
  end

  test "description/0 returns a non-empty string" do
    assert String.length(FileWrite.description()) > 0
  end

  test "schema/0 returns a map with path and content keys" do
    schema = FileWrite.schema()
    assert is_map(schema)
    assert Map.has_key?(schema, :path)
    assert Map.has_key?(schema, :content)
  end

  test "execute/1 writes content to a file" do
    assert {:ok, path} = FileWrite.execute(%{path: @tmp_file, content: "written content"})
    assert path == @tmp_file
    assert File.read!(@tmp_file) == "written content"
  end

  test "execute/1 returns {:error, reason} for invalid path" do
    result = FileWrite.execute(%{path: "/nonexistent_dir_xyz/file.txt", content: "test"})
    assert match?({:error, _}, result)
  end
end
