defmodule MusicianTui.Views.InputTest do
  use ExUnit.Case, async: true

  alias MusicianTui.Views.Input
  alias MusicianTui.Model

  describe "render/1" do
    test "returns a valid tagged tuple tree without crashing" do
      model = %Model{input: "", loading: false}

      result = Input.render(model)

      assert is_tuple(result)
      assert elem(result, 0) == :panel
    end

    test "panel title indicates ready state when not loading" do
      model = %Model{input: "hello", loading: false}

      {:panel, attrs, _} = Input.render(model)
      title = Keyword.fetch!(attrs, :title)

      assert title =~ "Input"
      assert title =~ "Enter to send"
    end

    test "panel title indicates waiting state when loading" do
      model = %Model{input: "hello", loading: true}

      {:panel, attrs, _} = Input.render(model)
      title = Keyword.fetch!(attrs, :title)

      assert title =~ "Input"
      assert title =~ "waiting"
    end

    test "label displays input buffer content with prompt prefix" do
      model = %Model{input: "test input", loading: false}

      {:panel, _, [{:label, attrs, _} | _]} = Input.render(model)
      content = Keyword.fetch!(attrs, :content)

      assert content =~ "> test input"
    end

    test "label shows empty prompt prefix when input is empty" do
      model = %Model{input: "", loading: false}

      {:panel, _, [{:label, attrs, _} | _]} = Input.render(model)
      content = Keyword.fetch!(attrs, :content)

      assert content == "> "
    end

    test "handles long input strings without crashing" do
      long_input = String.duplicate("a", 1000)
      model = %Model{input: long_input, loading: false}

      result = Input.render(model)
      {:panel, _, [{:label, attrs, _} | _]} = result
      content = Keyword.fetch!(attrs, :content)

      assert content =~ "> #{long_input}"
    end
  end
end
