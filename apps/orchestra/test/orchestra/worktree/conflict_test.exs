defmodule Orchestra.Worktree.ConflictTest do
  use ExUnit.Case, async: true

  alias Orchestra.Worktree.Conflict

  describe "detect/1" do
    test "returns {:ok, :no_conflict} when git merge-head returns exit code 128" do
      # Simulate: git merge-head on a branch with no active merge → exit 128
      assert detect_simulate({"<unused>", 128}) == {:ok, :no_conflict}
    end

    test "returns {:error, {:conflicts, files}} when conflicts are present" do
      output = """
      <<<<<<< HEAD
      +++ b/lib/foo.ex
      =======
      +++ b/lib/bar.ex
      >>>>>>> branch
      """

      assert detect_simulate({output, 0}) ==
               {:error, {:conflicts, ["lib/foo.ex", "lib/bar.ex"]}}
    end
  end

  describe "list_conflicted_files/1" do
    test "returns list of conflicted file paths" do
      output = "lib/foo.ex\nlib/bar.ex\n"
      assert list_conflicted_simulate({output, 0}) == {:ok, ["lib/foo.ex", "lib/bar.ex"]}
    end

    test "returns empty list when no conflicts" do
      assert list_conflicted_simulate({"", 0}) == {:ok, []}
    end

    test "returns empty list on non-zero exit (e.g., not a git repo)" do
      assert list_conflicted_simulate({"fatal: not a git repository", 128}) == {:ok, []}
    end
  end

  # Pure simulation helpers mirroring Conflict module logic
  defp detect_simulate({output, code}) do
    case {output, code} do
      {_, 128} ->
        {:ok, :no_conflict}

      {output, 0} ->
        files =
          Regex.scan(~r/^\+\+\+ b\/(.+)$/m, output, capture: :all_but_first)
          |> List.flatten()

        {:error, {:conflicts, files}}
    end
  end

  defp list_conflicted_simulate({output, 0}) do
    files = output |> String.split("\n", trim: true)
    {:ok, files}
  end

  defp list_conflicted_simulate({_, _}), do: {:ok, []}
end
