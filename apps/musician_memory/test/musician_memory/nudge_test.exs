defmodule MusicianMemory.NudgeTest do
  use ExUnit.Case, async: true

  alias MusicianMemory.Nudge

  test "should_nudge?/1 returns false when last nudge was recent" do
    last_nudge = DateTime.utc_now() |> DateTime.add(-5 * 60, :second) |> DateTime.to_iso8601()
    refute Nudge.should_nudge?(%{last_nudge_at: last_nudge, interval_minutes: 30})
  end

  test "should_nudge?/1 returns true when interval exceeded" do
    last_nudge = DateTime.utc_now() |> DateTime.add(-31 * 60, :second) |> DateTime.to_iso8601()
    assert Nudge.should_nudge?(%{last_nudge_at: last_nudge, interval_minutes: 30})
  end

  test "should_nudge?/1 returns true when no last nudge recorded" do
    assert Nudge.should_nudge?(%{last_nudge_at: nil, interval_minutes: 30})
  end

  test "nudge_message/0 returns a non-empty string" do
    msg = Nudge.nudge_message()
    assert is_binary(msg) and String.length(msg) > 0
  end
end
