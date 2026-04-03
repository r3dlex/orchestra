defmodule Orchestra.Worktree.ReportTest do
  use ExUnit.Case, async: true
  alias Orchestra.Worktree.Report

  test "generate/2 returns a non-empty string" do
    result = Report.generate("worker-1", %{status: :done, files_changed: 3})
    assert is_binary(result)
    assert String.length(result) > 0
  end
end
