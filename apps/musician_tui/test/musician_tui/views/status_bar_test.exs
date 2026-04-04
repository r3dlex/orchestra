defmodule MusicianTui.Views.StatusBarTest do
  use ExUnit.Case, async: true

  alias MusicianTui.Views.StatusBar
  alias MusicianTui.Model

  describe "render/1" do
    test "returns a valid tagged tuple tree without crashing" do
      model = %Model{
        provider: "minimax",
        model: "abab6.5s-chat",
        token_count: 0
      }

      result = StatusBar.render(model)

      assert is_tuple(result)
      assert elem(result, 0) == :bar
    end

    test "tree contains a label element with provider, model, and token info" do
      model = %Model{
        provider: "claude",
        model: "claude-sonnet-4-6",
        token_count: 42
      }

      {:bar, _, [{:label, attrs, _} | _]} = StatusBar.render(model)
      content = Keyword.fetch!(attrs, :content)

      assert content =~ "claude"
      assert content =~ "claude-sonnet-4-6"
      assert content =~ "42"
    end

    test "handles zero token count" do
      model = %Model{
        provider: "minimax",
        model: "abab6.5s-chat",
        token_count: 0
      }

      {:bar, _, [{:label, attrs, _} | _]} = StatusBar.render(model)
      content = Keyword.fetch!(attrs, :content)

      assert content =~ "Tokens: 0"
    end

    test "includes quit instructions in the status text" do
      model = %Model{
        provider: "gemini",
        model: "gemini-pro",
        token_count: 100
      }

      {:bar, _, [{:label, attrs, _} | _]} = StatusBar.render(model)
      content = Keyword.fetch!(attrs, :content)

      assert content =~ "Ctrl+C"
    end
  end
end
