defmodule MusicianCli.Cli do
  @moduledoc """
  CLI entrypoint. Parses arguments and dispatches to subcommands.
  """

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

  def main(args) do
    {opts, remaining, _invalid} = OptionParser.parse(args, switches: @switches, aliases: @aliases)

    cond do
      opts[:help] -> print_help()
      opts[:prompt] -> run_prompt(opts)
      true -> dispatch(remaining, opts)
    end
  end

  defp dispatch(["login" | _rest], _opts), do: IO.puts("Login not yet implemented")
  defp dispatch(["config" | _rest], _opts), do: IO.puts("Config not yet implemented")
  defp dispatch(["help" | _rest], _opts), do: print_help()
  defp dispatch([], _opts), do: start_tui()
  defp dispatch([cmd | _], _opts), do: IO.puts("Unknown command: #{cmd}")

  defp run_prompt(_opts), do: IO.puts("Prompt mode not yet implemented")
  defp start_tui, do: IO.puts("TUI not yet implemented")

  defp print_help do
    IO.puts("""
    musician — provider-agnostic LLM CLI

    Usage:
      musician [options]
      musician <command>

    Options:
      --provider, -p <name>   Provider to use (minimax, claude, codex, gemini, ollama)
      --prompt <text>         Run a single prompt (non-interactive)
      --non-interactive       Disable TUI, output to stdout
      --output-file <path>    Write response to file
      --help, -h              Show this help

    Commands:
      login     Authenticate with a provider
      config    Show or edit configuration
      help      Show this help
    """)
  end
end
