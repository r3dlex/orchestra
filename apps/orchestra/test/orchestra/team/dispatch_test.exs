defmodule Orchestra.Team.DispatchTest do
  use ExUnit.Case, async: true

  alias Orchestra.Team.Dispatch

  describe "dispatch_workers/1" do
    test "returns {:error, :no_backends} when no backends are available" do
      # Mock Registry.detect to return no backends
      Application.put_env(:orchestra, :enabled_backends, [:nonexistent])

      on_exit(fn ->
        Application.delete_env(:orchestra, :enabled_backends)
      end)

      assert Dispatch.dispatch_workers(3) == {:error, :no_backends}
    end

    test "returns worker descriptors when backends are available" do
      # Only enable one backend so round-robin is deterministic
      Application.put_env(:orchestra, :enabled_backends, [:musician])

      on_exit(fn ->
        Application.delete_env(:orchestra, :enabled_backends)
      end)

      workers = Dispatch.dispatch_workers(3)

      assert is_list(workers)
      assert length(workers) == 3
      assert Enum.all?(workers, &match?(%{worker_id: _, backend: {_, _}}, &1))
    end

    test "round-robins across available backends" do
      Application.put_env(:orchestra, :enabled_backends, [:musician, :claude])

      on_exit(fn ->
        Application.delete_env(:orchestra, :enabled_backends)
      end)

      workers = Dispatch.dispatch_workers(4)

      assert length(workers) == 4
      ids = Enum.map(workers, & &1.worker_id)
      assert ids == [1, 2, 3, 4]
    end
  end
end
