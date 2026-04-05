defmodule Orchestra.Worktree.ReportTest do
  use ExUnit.Case, async: true

  alias Orchestra.Worktree.Report

  describe "summary/1" do
    test "returns {:ok, reports} for omc-worker-* directories" do
      tmp_dir = System.tmp_dir!() |> Path.join("orchestra_report_test_#{:rand.uniform(100_000)}")
      File.mkdir_p!(Path.join(tmp_dir, "omc-worker-1"))
      File.mkdir_p!(Path.join(tmp_dir, "omc-worker-2"))
      File.mkdir_p!(Path.join(tmp_dir, ".keep"))

      on_exit(fn -> File.rm_rf!(tmp_dir) end)

      assert {:ok, reports} = Report.summary(tmp_dir)
      assert length(reports) == 2
      names = Enum.map(reports, & &1.name) |> Enum.sort()
      assert names == ["omc-worker-1", "omc-worker-2"]
    end

    test "each report has name, path, branch, and status fields" do
      tmp_dir = System.tmp_dir!() |> Path.join("orchestra_report_fields_test_#{:rand.uniform(100_000)}")
      File.mkdir_p!(Path.join(tmp_dir, "omc-worker-feature-x"))

      on_exit(fn -> File.rm_rf!(tmp_dir) end)

      assert {:ok, [report]} = Report.summary(tmp_dir)
      assert report.name == "omc-worker-feature-x"
      assert report.branch == "feature-x"
      assert is_binary(report.path)
      assert report.status == :clean or match?({:dirty, _}, report.status)
    end

    test "returns {:ok, []} for empty directory" do
      tmp_dir = System.tmp_dir!() |> Path.join("orchestra_report_empty_#{:rand.uniform(100_000)}")
      File.mkdir_p!(tmp_dir)

      on_exit(fn -> File.rm_rf!(tmp_dir) end)

      assert {:ok, []} = Report.summary(tmp_dir)
    end
  end
end
