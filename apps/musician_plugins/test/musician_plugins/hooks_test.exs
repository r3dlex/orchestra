defmodule MusicianPlugins.HooksTest do
  use ExUnit.Case, async: true

  alias MusicianPlugins.Hooks

  test "dispatch/3 calls all registered handlers for an event" do
    hooks = Hooks.new()
    test_pid = self()
    handler = fn _ctx -> send(test_pid, :hook_called) end
    hooks = Hooks.register_hook(hooks, :on_message, handler)
    Hooks.dispatch(hooks, :on_message, %{content: "hello"})
    assert_receive :hook_called, 1000
  end

  test "dispatch/3 is a no-op when no handlers registered" do
    hooks = Hooks.new()
    assert :ok = Hooks.dispatch(hooks, :on_message, %{})
  end

  test "register_hook/3 accumulates multiple handlers" do
    hooks = Hooks.new()
    hooks = Hooks.register_hook(hooks, :on_load, fn _ -> :a end)
    hooks = Hooks.register_hook(hooks, :on_load, fn _ -> :b end)
    handlers = Hooks.handlers_for(hooks, :on_load)
    assert length(handlers) == 2
  end
end
