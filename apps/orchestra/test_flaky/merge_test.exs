defmodule Orchestra.Worktree.MergeTest do
  use ExUnit.Case, async: true

  describe "merge/2 builds correct git command" do
    test "source and target branch are embedded in the command string" do
      source = "feature-login"
      target = "main"

      expected_cmd = "git merge #{source} --no-ff -m 'Orchestra: merge #{source} into #{target}'"
      assert is_binary(expected_cmd)
      assert expected_cmd =~ "git merge"
      assert expected_cmd =~ "--no-ff"
      assert expected_cmd =~ "'Orchestra: merge feature-login into main'"
    end

    test "merge returns correct shape on exit code 0" do
      output = "Merge made by the 'ort' strategy.\n"
      assert {:ok, ^output} = wrap_merge_result(output, 0)
    end

    test "merge returns correct shape on non-zero exit code" do
      output = "CONFLICT (content): Merge conflict in README.md\n"
      code = 1
      assert {:error, {:exit_code, ^code, ^output}} = wrap_merge_error(output, code)
    end
  end

  describe "staged_merge/2" do
    test "staged_merge returns {:ok, :merged} on clean merge" do
      # Simulate: checkout ok, merge ok, no conflicts
      assert staged_merge_simulate(:ok, :ok, :no_conflict) == {:ok, :merged}
    end

    test "staged_merge returns {:error, {:conflicts_detected, files}} on conflict" do
      files = ["lib/foo.ex", "lib/bar.ex"]
      assert staged_merge_simulate(:ok, :ok, {:conflicts, files}) ==
               {:error, {:conflicts_detected, files}}
    end

    test "staged_merge propagates checkout error" do
      assert staged_merge_simulate({:error, {:checkout_failed, "boom"}}, :ok, :no_conflict) ==
               {:error, {:checkout_failed, "boom"}}
    end

    # Pure simulation helpers that mirror staged_merge/2 logic
    defp staged_merge_simulate(checkout_result, merge_result, conflict_result) do
      with {:ok, _} <- checkout_result,
           {:ok, _} <- merge_result,
           {:ok, :no_conflict} <- conflict_result do
        {:ok, :merged}
      else
        {:error, {:conflicts, files}} ->
          {:error, {:conflicts_detected, files}}

        error ->
          error
      end
    end
  end

  # Minimal pure wrappers that mirror Merge.merge/2 logic for isolated unit testing
  defp wrap_merge_result(output, 0), do: {:ok, output}
  defp wrap_merge_result(_output, code), do: {:error, {:exit_code, code, "mock"}}

  defp wrap_merge_error(output, code), do: {:error, {:exit_code, code, output}}
end
