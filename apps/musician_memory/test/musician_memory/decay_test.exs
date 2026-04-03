defmodule MusicianMemory.DecayTest do
  use ExUnit.Case, async: true

  alias MusicianMemory.Decay

  test "stale?/1 returns false for recent project memory" do
    record = %{"type" => "project", "updated_at" => DateTime.utc_now() |> DateTime.to_iso8601()}
    refute Decay.stale?(record)
  end

  test "stale?/1 returns true for project memory older than 90 days" do
    old_date =
      DateTime.utc_now() |> DateTime.add(-91 * 24 * 3600, :second) |> DateTime.to_iso8601()

    record = %{"type" => "project", "updated_at" => old_date}
    assert Decay.stale?(record)
  end

  test "stale?/1 always returns false for reference type (never decays)" do
    old_date =
      DateTime.utc_now() |> DateTime.add(-365 * 24 * 3600, :second) |> DateTime.to_iso8601()

    record = %{"type" => "reference", "updated_at" => old_date}
    refute Decay.stale?(record)
  end
end
