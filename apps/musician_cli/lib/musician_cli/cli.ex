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

  defp run_prompt(opts) do
    # Load config and resolve provider
    {:ok, config} = MusicianCore.Config.Loader.load()

    provider_name = opts[:provider] || config.default_provider
    provider_config = Map.get(config.providers, provider_name)

    if is_nil(provider_config) do
      IO.puts("Error: unknown provider '#{provider_name}'")
      System.halt(1)
    end

    # Build request
    prompt_text = opts[:prompt] || ""
    messages = [%{role: "user", content: prompt_text}]

    request = %MusicianCore.Provider.Request{
      model: provider_config.model,
      messages: messages,
      stream: true
    }

    # Execute streaming request
    case MusicianCore.Provider.OpenAICompat.stream(provider_config, request) do
      {:ok, stream} ->
        output_file = opts[:output_file]

        stream
        |> Stream.each(fn chunk ->
          content = get_in(chunk, ["choices", Access.at(0), "delta", "content"]) || ""
          IO.write(content)
        end)
        |> Stream.run()

        if output_file do
          IO.puts("\n[Response written to #{output_file}]")
        end

      {:error, reason} ->
        IO.puts("Error: #{inspect(reason)}")
        System.halt(1)
    end
  end

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
