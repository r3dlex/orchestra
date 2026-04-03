defmodule MusicianTools.FileReadTest do
  use ExUnit.Case, async: true
  alias MusicianTools.FileRead

  @tmp_file System.tmp_dir!() |> Path.join("musician_tools_test_#{:rand.uniform(100_000)}.txt")

  setup do
    File.write!(@tmp_file, "test content")
    on_exit(fn -> File.rm(@tmp_file) end)
    :ok
  end

  test "name/0 returns file_read" do
    assert FileRead.name() == "file_read"
  end

  test "description/0 returns a non-empty string" do
    assert String.length(FileRead.description()) > 0
  end

  test "schema/0 returns a map with path key" do
    schema = FileRead.schema()
    assert is_map(schema)
    assert Map.has_key?(schema, :path)
  end

  test "execute/1 reads an existing file" do
    assert {:ok, content} = FileRead.execute(%{path: @tmp_file})
    assert content == "test content"
  end

  test "execute/1 returns {:error, :not_found} for missing file" do
    assert {:error, :not_found} = FileRead.execute(%{path: "/nonexistent/path/file.txt"})
  end
end
