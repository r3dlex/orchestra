defmodule MusicianTui.AppTest do
  use ExUnit.Case, async: true

  alias MusicianTui.{App, Model}

  @init_context %{window: %{height: 40, width: 120}}

  describe "init/1" do
    test "returns initial model with empty conversation" do
      model = App.init(@init_context)

      assert %Model{} = model
      assert model.messages == []
      assert model.input == ""
      assert model.loading == false
    end

    test "initial model has default provider" do
      model = App.init(@init_context)
      assert model.provider == "minimax"
    end
  end

  describe "update/2" do
    test "{:input, char} appends to input buffer" do
      model = App.init(@init_context)
      updated = App.update(model, {:input, ?H})
      assert updated.input == "H"

      updated2 = App.update(updated, {:input, ?i})
      assert updated2.input == "Hi"
    end

    test "Enter submits input and clears buffer" do
      model = %Model{input: "Hello world"}
      updated = App.update(model, {:event, %{ch: ?\r}})

      assert updated.input == ""
      assert updated.loading == true
      assert length(updated.messages) == 1
      assert hd(updated.messages).role == "user"
      assert hd(updated.messages).content == "Hello world"
    end

    test "Enter with empty input does nothing" do
      model = %Model{input: ""}
      updated = App.update(model, {:event, %{ch: ?\r}})
      assert updated == model
    end

    test "backspace removes last character" do
      model = %Model{input: "Hello"}
      updated = App.update(model, {:event, %{ch: 127}})
      assert updated.input == "Hell"
    end

    test "{:add_message, role, content} appends a message" do
      model = App.init(@init_context)
      updated = App.update(model, {:add_message, "assistant", "Hi there!"})

      assert length(updated.messages) == 1
      assert hd(updated.messages).role == "assistant"
      assert hd(updated.messages).content == "Hi there!"
    end

    test "{:set_loading, bool} updates loading state" do
      model = App.init(@init_context)
      updated = App.update(model, {:set_loading, true})
      assert updated.loading == true
    end

    test "{:set_provider, name} updates provider" do
      model = App.init(@init_context)
      updated = App.update(model, {:set_provider, "claude"})
      assert updated.provider == "claude"
    end

    test "unknown messages return model unchanged" do
      model = App.init(@init_context)
      updated = App.update(model, :unknown_event)
      assert updated == model
    end

    test "update/2 with {:set_provider, provider} updates model.provider" do
      model = App.init(%{window: %{}})
      updated = App.update(model, {:set_provider, "claude"})
      assert updated.provider == "claude"
    end

    test "update/2 with {:set_model, model_name} updates model.model" do
      model = App.init(%{window: %{}})
      updated = App.update(model, {:set_model, "claude-sonnet-4-6"})
      assert updated.model == "claude-sonnet-4-6"
    end

    test "update/2 with two {:add_message} calls accumulates messages in order" do
      model = App.init(%{window: %{}})
      m1 = App.update(model, {:add_message, "user", "first"})
      m2 = App.update(m1, {:add_message, "assistant", "second"})
      assert length(m2.messages) == 2
      assert Enum.at(m2.messages, 0).role == "user"
      assert Enum.at(m2.messages, 0).content == "first"
      assert Enum.at(m2.messages, 1).role == "assistant"
      assert Enum.at(m2.messages, 1).content == "second"
    end

    test "model has provider field defaulting to minimax" do
      model = App.init(%{window: %{}})
      assert model.provider == "minimax"
    end

    test "model has model field defaulting to abab6.5s-chat" do
      model = App.init(%{window: %{}})
      assert model.model == "abab6.5s-chat"
    end
  end
end
