defmodule Orchestra.Team.DispatchTest do
  use ExUnit.Case, async: true
  alias Orchestra.Team.Dispatch

  @backends [{:musician, "/usr/local/bin/musician"}, {:claude, "/usr/local/bin/claude"}]

  test "route/3 returns a backend from the available list" do
    backend = Dispatch.route(@backends, "task description", %{})
    assert backend in @backends
  end

  test "route/3 returns {:error, :no_backends} for empty list" do
    assert {:error, :no_backends} = Dispatch.route([], "task", %{})
  end
end
