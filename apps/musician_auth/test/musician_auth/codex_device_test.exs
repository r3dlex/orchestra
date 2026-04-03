defmodule MusicianAuth.CodexDeviceTest do
  use ExUnit.Case, async: true

  alias MusicianAuth.CodexDevice

  test "exchange_device_code/1 function exists with arity 1" do
    assert {:exchange_device_code, 1} in CodexDevice.__info__(:functions)
  end

  test "request_device_code/0 function exists" do
    assert {:request_device_code, 0} in CodexDevice.__info__(:functions)
  end

  test "poll_for_token/1 function exists" do
    assert {:poll_for_token, 1} in CodexDevice.__info__(:functions)
  end
end
