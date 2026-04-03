defmodule MusicianAuth.PkceTest do
  use ExUnit.Case, async: true

  alias MusicianAuth.Pkce

  describe "generate_verifier/0" do
    test "returns a non-empty base64url string" do
      verifier = Pkce.generate_verifier()
      assert is_binary(verifier)
      assert byte_size(verifier) > 0
    end

    test "generates unique verifiers each time" do
      v1 = Pkce.generate_verifier()
      v2 = Pkce.generate_verifier()
      assert v1 != v2
    end
  end

  describe "generate_challenge/1" do
    test "PKCE challenge is SHA256(verifier) base64url-encoded" do
      verifier = "test-verifier-string"
      challenge = Pkce.generate_challenge(verifier)

      expected =
        :crypto.hash(:sha256, verifier)
        |> Base.url_encode64(padding: false)

      assert challenge == expected
    end

    test "challenge is different from verifier" do
      verifier = Pkce.generate_verifier()
      challenge = Pkce.generate_challenge(verifier)
      assert challenge != verifier
    end

    test "same verifier always produces same challenge" do
      verifier = "deterministic-verifier"
      assert Pkce.generate_challenge(verifier) == Pkce.generate_challenge(verifier)
    end
  end

  describe "valid_challenge?/2" do
    test "returns true for matching verifier and challenge" do
      verifier = Pkce.generate_verifier()
      challenge = Pkce.generate_challenge(verifier)
      assert Pkce.valid_challenge?(verifier, challenge) == true
    end

    test "returns false for wrong verifier" do
      verifier = Pkce.generate_verifier()
      challenge = Pkce.generate_challenge(verifier)
      assert Pkce.valid_challenge?("wrong-verifier", challenge) == false
    end
  end
end
