defmodule Orchestra.RalphTest do
  use ExUnit.Case, async: true
  alias Orchestra.Ralph

  test "run/2 with a verifier that always passes returns {:ok, :done}" do
    verifier = fn _state -> :pass end
    assert {:ok, :done} = Ralph.run("do something", verifier: verifier, max_retries: 3)
  end

  test "run/2 with a verifier that always fails returns {:error, :max_retries}" do
    verifier = fn _state -> :fail end
    assert {:error, :max_retries} = Ralph.run("do something", verifier: verifier, max_retries: 2)
  end

  test "run/2 with a verifier that passes on 2nd attempt returns {:ok, :done}" do
    counter = :counters.new(1, [])
    verifier = fn _state ->
      :counters.add(counter, 1, 1)
      if :counters.get(counter, 1) >= 2, do: :pass, else: :fail
    end
    assert {:ok, :done} = Ralph.run("task", verifier: verifier, max_retries: 5)
  end
end
