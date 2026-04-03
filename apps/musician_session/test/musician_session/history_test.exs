defmodule MusicianSession.HistoryTest do
  use ExUnit.Case, async: true

  alias MusicianSession.History

  @tmp_file System.tmp_dir!()
            |> Path.join("musician_session_test_#{:rand.uniform(100_000)}.jsonl")

  setup do
    File.rm(@tmp_file)
    on_exit(fn -> File.rm(@tmp_file) end)
    :ok
  end

  test "append/2 and read_all/1 round-trip a session entry" do
    entry = %{
      session_id: "test-uuid-001",
      timestamp: "2026-04-03T10:00:00Z",
      project_dir: "/tmp/test",
      provider: "minimax",
      model: "abab6.5s-chat",
      prompt_summary: "tested the history module",
      token_count: 100,
      tools_used: ["bash"],
      duration_seconds: 10
    }

    :ok = History.append(@tmp_file, entry)
    {:ok, entries} = History.read_all(@tmp_file)
    assert length(entries) == 1
    assert hd(entries)["session_id"] == "test-uuid-001"
    assert hd(entries)["provider"] == "minimax"
  end

  test "append/2 appends multiple entries" do
    History.append(@tmp_file, %{
      session_id: "s1",
      timestamp: "2026-01-01T00:00:00Z",
      prompt_summary: "first"
    })

    History.append(@tmp_file, %{
      session_id: "s2",
      timestamp: "2026-01-02T00:00:00Z",
      prompt_summary: "second"
    })

    {:ok, entries} = History.read_all(@tmp_file)
    assert length(entries) == 2
  end

  test "read_all/1 returns {:error, :not_found} for missing file" do
    assert {:error, :not_found} = History.read_all("/nonexistent/history.jsonl")
  end

  test "prune/2 keeps only the most recent N entries" do
    for i <- 1..5 do
      History.append(@tmp_file, %{
        session_id: "s#{i}",
        timestamp: "2026-01-0#{i}T00:00:00Z",
        prompt_summary: "entry #{i}"
      })
    end

    :ok = History.prune(@tmp_file, 3)
    {:ok, entries} = History.read_all(@tmp_file)
    assert length(entries) == 3
  end
end
