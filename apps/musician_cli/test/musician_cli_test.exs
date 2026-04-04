defmodule MusicianCliTest do
  use ExUnit.Case, async: true

  alias MusicianCli.Cli

  @switches [
    provider: :string,
    prompt: :string,
    non_interactive: :boolean,
    output_file: :string,
    help: :boolean
  ]

  @aliases [
    p: :provider,
    h: :help
  ]

  # ---------------------------------------------------------------------------
  # OptionParser parsing tests
  # ---------------------------------------------------------------------------

  describe "OptionParser parsing" do
    test "parses --provider long form" do
      {opts, [], []} =
        OptionParser.parse(["--provider", "claude"],
          switches: @switches,
          aliases: @aliases
        )

      assert opts[:provider] == "claude"
    end

    test "parses -p short form for provider" do
      {opts, [], []} =
        OptionParser.parse(["-p", "minimax"],
          switches: @switches,
          aliases: @aliases
        )

      assert opts[:provider] == "minimax"
    end

    test "parses --prompt" do
      {opts, [], []} =
        OptionParser.parse(["--prompt", "Hello world"],
          switches: @switches,
          aliases: @aliases
        )

      assert opts[:prompt] == "Hello world"
    end

    test "parses --output-file" do
      {opts, [], []} =
        OptionParser.parse(["--output-file", "/tmp/out.txt"],
          switches: @switches,
          aliases: @aliases
        )

      assert opts[:output_file] == "/tmp/out.txt"
    end

    test "parses --non-interactive boolean flag" do
      {opts, [], []} =
        OptionParser.parse(["--non-interactive"],
          switches: @switches,
          aliases: @aliases
        )

      assert opts[:non_interactive] == true
    end

    test "parses -h as alias for --help" do
      {opts, [], []} =
        OptionParser.parse(["-h"],
          switches: @switches,
          aliases: @aliases
        )

      assert opts[:help] == true
    end

    test "captures remaining positional args separately from options" do
      {opts, remaining, []} =
        OptionParser.parse(["login", "--provider", "claude"],
          switches: @switches,
          aliases: @aliases
        )

      assert opts[:provider] == "claude"
      assert remaining == ["login"]
    end

    test "multiple options together" do
      {opts, remaining, []} =
        OptionParser.parse(
          ["--prompt", "sing a song", "--provider", "claude", "--non-interactive"],
          switches: @switches,
          aliases: @aliases
        )

      assert opts[:prompt] == "sing a song"
      assert opts[:provider] == "claude"
      assert opts[:non_interactive] == true
      assert remaining == []
    end
  end

  # ---------------------------------------------------------------------------
  # main/1 dispatch routing
  # ---------------------------------------------------------------------------

  describe "main/1 with --help" do
    test "--help flag does not raise and prints help text" do
      output =
        ExUnit.CaptureIO.capture_io(fn ->
          Cli.main(["--help"])
        end)

      assert output =~ "musician"
      assert output =~ "--provider"
      assert output =~ "--prompt"
      assert output =~ "--non-interactive"
      assert output =~ "--output-file"
      assert output =~ "--help"
      assert output =~ "login"
      assert output =~ "config"
    end

    test "-h alias does not raise and prints help text" do
      output =
        ExUnit.CaptureIO.capture_io(fn ->
          Cli.main(["-h"])
        end)

      assert output =~ "musician"
      assert output =~ "--provider"
    end
  end

  describe "main/1 with empty args (start_tui path)" do
    @tag :tui
    test "empty list attempts to start the TUI" do
      # Ratatouille requires a terminal/TUI environment which is not available in CI.
      # This is verified by the actual integration test that runs the TUI in dev.
      # Skipping in automated test runs.
      :skip
    end
  end

  describe "main/1 with subcommands" do
    test "login subcommand does not raise" do
      output =
        ExUnit.CaptureIO.capture_io(fn ->
          Cli.main(["login"])
        end)

      assert output =~ "Login not yet implemented"
    end

    test "config subcommand does not raise" do
      output =
        ExUnit.CaptureIO.capture_io(fn ->
          Cli.main(["config"])
        end)

      assert output =~ "Config not yet implemented"
    end

    test "help subcommand prints help text" do
      output =
        ExUnit.CaptureIO.capture_io(fn ->
          Cli.main(["help"])
        end)

      assert output =~ "musician"
      assert output =~ "--provider"
    end

    test "unknown subcommand prints error and does not raise" do
      output =
        ExUnit.CaptureIO.capture_io(fn ->
          Cli.main(["foobar"])
        end)

      assert output =~ "Unknown command: foobar"
    end

    test "unknown subcommand after options still routes correctly" do
      output =
        ExUnit.CaptureIO.capture_io(fn ->
          Cli.main(["--provider", "claude", "foobar"])
        end)

      assert output =~ "Unknown command: foobar"
    end
  end

  # ---------------------------------------------------------------------------
  # Help output content tests (tested through main/1 since print_help is private)
  # ---------------------------------------------------------------------------

  describe "help output content" do
    test "help includes Usage, Options, and Commands sections" do
      output =
        ExUnit.CaptureIO.capture_io(fn ->
          Cli.main(["--help"])
        end)

      assert output =~ "Usage:"
      assert output =~ "Options:"
      assert output =~ "Commands:"
    end

    test "help lists all documented options" do
      output =
        ExUnit.CaptureIO.capture_io(fn ->
          Cli.main(["--help"])
        end)

      assert output =~ "--provider, -p"
      assert output =~ "--prompt"
      assert output =~ "--non-interactive"
      assert output =~ "--output-file"
      assert output =~ "--help, -h"
    end

    test "help lists all documented subcommands" do
      output =
        ExUnit.CaptureIO.capture_io(fn ->
          Cli.main(["--help"])
        end)

      assert output =~ "login"
      assert output =~ "config"
      assert output =~ "help"
    end
  end
end
