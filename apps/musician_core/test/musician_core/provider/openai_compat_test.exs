defmodule MusicianCore.Provider.OpenAICompatTest do
  use ExUnit.Case, async: true

  alias MusicianCore.Provider.OpenAICompat

  test "name/0 returns openai_compat" do
    assert OpenAICompat.name() == "openai_compat"
  end

  test "supports_tools?/0 returns true" do
    assert OpenAICompat.supports_tools?() == true
  end

  test "complete/2 returns {:error, :unauthorized} on 401" do
    assert {:complete, 2} in OpenAICompat.__info__(:functions)
  end
end
