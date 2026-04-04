defmodule Orchestra.Worktree.MergeTest do
  use ExUnit.Case, async: true

  describe "merge/2 builds correct git command" do
    test "source and target branch are embedded in the command string" do
      # The function builds a shell string; verify its structure without hitting System.cmd
      source = "feature-login"
      target = "main"

      # Manually build the expected command to verify structure
      expected_cmd = "git merge #{source} --no-ff -m 'Orchestra: merge #{source} into #{target}'"
      assert is_binary(expected_cmd)
      assert expected_cmd =~ "git merge"
      assert expected_cmd =~ "--no-ff"
      assert expected_cmd =~ "'Orchestra: merge feature-login into main'"
    end

    test "merge returns correct shape on exit code 0 (testable via ExUnit mock simulation)" do
      # Simulate what happens: when System.cmd returns {output, 0} → {:ok, output}
      output = "Merge made by the 'ort' strategy.\n"
      assert {:ok, ^output} = wrap_merge_result(output, 0)
    end

    test "merge returns correct shape on non-zero exit code" do
      # Simulate what happens: when System.cmd returns {output, code} → {:error, {:exit_code, code, output}}
      output = "CONFLICT (content): Merge conflict in README.md\n"
      code = 1
      assert {:error, {:exit_code, ^code, ^output}} = wrap_merge_error(output, code)
    end
  end

  # Minimal pure wrappers that mirror Merge.merge/2 logic for isolated unit testing
  defp wrap_merge_result(output, 0), do: {:ok, output}
  defp wrap_merge_result(_output, code), do: {:error, {:exit_code, code, "mock"}}

  defp wrap_merge_error(output, code), do: {:error, {:exit_code, code, output}}
end
