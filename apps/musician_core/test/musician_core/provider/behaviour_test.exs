defmodule MusicianCore.Provider.BehaviourTest do
  use ExUnit.Case, async: true

  alias MusicianCore.Provider.Behaviour

  test "behaviour module exists and defines callbacks" do
    # Verify the behaviour module is loaded
    assert is_atom(Behaviour)

    callbacks = Behaviour.behaviour_info(:callbacks)
    callback_names = Enum.map(callbacks, fn {name, _arity} -> name end)

    assert :name in callback_names
    assert :complete in callback_names
    assert :stream in callback_names
    assert :list_models in callback_names
    assert :supports_tools? in callback_names
  end
end
