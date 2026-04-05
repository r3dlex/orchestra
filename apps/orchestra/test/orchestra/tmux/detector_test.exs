defmodule Orchestra.Tmux.DetectorTest do
  use ExUnit.Case, async: true

  alias Orchestra.Tmux.Detector

  describe "available?/0" do
    test "returns tmux availability result" do
      result = Detector.available?()

      assert match?({:ok, p, v} when is_binary(p) and is_tuple(v), result) ||
               match?({:error, :tmux_not_found}, result) ||
               match?({:error, {:tmux_too_old, v}} when is_tuple(v), result) ||
               match?({:error, {:tmux_version_check_failed, c}} when is_integer(c), result)
    end
  end

  describe "version parsing" do
    test "version tuple structure when tmux is available" do
      result = Detector.available?()

      case result do
        {:ok, path, version} ->
          assert is_binary(path)
          assert is_tuple(version)
          assert tuple_size(version) == 3

        {:error, {:tmux_too_old, version}} ->
          assert is_tuple(version)
          assert tuple_size(version) == 3

        {:error, :tmux_not_found} ->
          assert true

        {:error, {:tmux_version_check_failed, code}} ->
          assert is_integer(code)
      end
    end
  end
end
