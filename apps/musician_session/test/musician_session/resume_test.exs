defmodule MusicianSession.ResumeTest do
  use ExUnit.Case, async: true

  alias MusicianSession.Resume
  alias MusicianSession.History

  setup do
    tmp_path =
      System.tmp_dir!()
      |> Path.join("musician_session_resume_test_#{:rand.uniform(100_000)}.jsonl")

    Application.put_env(:musician_session, :history_path, tmp_path)

    on_exit(fn ->
      File.rm(tmp_path)
      Application.delete_env(:musician_session, :history_path)
    end)

    {:ok, path: tmp_path}
  end

  test "latest/0 returns last session entry", %{path: path} do
    History.append(path, %{
      session_id: "s1",
      timestamp: "2026-01-01T00:00:00Z",
      project_dir: "/tmp/test",
      provider: "minimax",
      prompt_summary: "first session"
    })

    History.append(path, %{
      session_id: "s2",
      timestamp: "2026-01-02T00:00:00Z",
      project_dir: "/tmp/test",
      provider: "minimax",
      prompt_summary: "latest session"
    })

    assert {:ok, prompt} = Resume.latest()
    assert prompt.summary == "latest session"
    assert prompt.project_dir == "/tmp/test"
  end

  test "latest/0 returns {:error, :no_sessions} when history is empty", %{path: path} do
    assert Resume.latest() == {:error, :no_sessions}
  end

  test "latest/0 returns {:error, :not_found} when history file is missing", %{
    path: _path
  } do
    Application.delete_env(:musician_session, :history_path)
    Application.put_env(:musician_session, :history_path, "/nonexistent/history.jsonl")
    assert Resume.latest() == {:error, :not_found}
  end

  test "by_project/1 returns at most 5 most-recent entries for project", %{path: path} do
    for i <- 1..7 do
      History.append(path, %{
        session_id: "s#{i}",
        timestamp: "2026-01-0#{i}T00:00:00Z",
        project_dir: "/tmp/p1",
        prompt_summary: "entry #{i}"
      })
    end

    History.append(path, %{
      session_id: "s99",
      timestamp: "2026-01-10T00:00:00Z",
      project_dir: "/tmp/p2",
      prompt_summary: "other project"
    })

    assert {:ok, matches} = Resume.by_project("/tmp/p1")
    assert length(matches) == 5
    assert Enum.all?(matches, &(&1.project_dir == "/tmp/p1"))
  end

  test "by_project/1 returns empty list when no sessions for project", %{path: path} do
    History.append(path, %{
      session_id: "s1",
      timestamp: "2026-01-01T00:00:00Z",
      project_dir: "/tmp/other",
      prompt_summary: "some project"
    })

    assert {:ok, matches} = Resume.by_project("/tmp/nonexistent")
    assert matches == []
  end
end
