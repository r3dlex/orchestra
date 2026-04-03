defmodule MusicianCore.Config.Loader do
  @moduledoc """
  Loads and merges Musician configuration from YAML files.

  Load order (later values override earlier):
  1. Built-in defaults
  2. Global config: ~/.musician/config.yaml
  3. Local config: .musician/config.yaml (relative to cwd)
  """

  alias MusicianCore.Config.{Schema, Presets}
  alias Schema.{ProviderConfig, MemoryConfig, SkillsConfig, SessionConfig, TuiConfig}

  @global_config_path "~/.musician/config.yaml"
  @local_config_path ".musician/config.yaml"

  @doc """
  Loads config from the default locations (global + local merge).
  Returns `{:ok, %Schema{}}` or `{:error, reason}`.
  """
  @spec load() :: {:ok, Schema.t()} | {:error, term()}
  def load do
    load(global: @global_config_path, local: @local_config_path)
  end

  @doc """
  Loads config from explicit paths.
  Options: `global:` and/or `local:` paths (strings or nil to skip).
  """
  @spec load(keyword()) :: {:ok, Schema.t()} | {:error, term()}
  def load(opts) do
    global_path = Keyword.get(opts, :global, @global_config_path)
    local_path = Keyword.get(opts, :local, @local_config_path)

    with global_raw <- load_yaml_file(global_path),
         local_raw <- load_yaml_file(local_path),
         merged <- deep_merge(global_raw, local_raw),
         {:ok, config} <- build_config(merged) do
      {:ok, config}
    end
  end

  # --- Private ---

  defp load_yaml_file(nil), do: %{}

  defp load_yaml_file(path) do
    expanded = Path.expand(path)

    case File.read(expanded) do
      {:ok, content} ->
        case YamlElixir.read_from_string(content) do
          {:ok, parsed} when is_map(parsed) -> parsed
          _ -> %{}
        end

      {:error, _} ->
        %{}
    end
  end

  defp deep_merge(base, override) when is_map(base) and is_map(override) do
    Map.merge(base, override, fn _key, v1, v2 ->
      if is_map(v1) and is_map(v2), do: deep_merge(v1, v2), else: v2
    end)
  end

  defp deep_merge(_base, override), do: override

  defp build_config(raw) do
    providers = build_providers(Map.get(raw, "providers", %{}))

    config = %Schema{
      default_provider: Map.get(raw, "default_provider", "minimax"),
      providers: providers,
      memory: build_memory(Map.get(raw, "memory", %{})),
      skills: build_skills(Map.get(raw, "skills", %{})),
      session: build_session(Map.get(raw, "session", %{})),
      tui: build_tui(Map.get(raw, "tui", %{})),
      plugins: Map.get(raw, "plugins", %{})
    }

    {:ok, config}
  end

  defp build_providers(raw_providers) when map_size(raw_providers) == 0 do
    # No config file or no providers in config — use all presets
    presets = Presets.all()
    presets
  end

  defp build_providers(raw_providers) do
    presets = Presets.all()

    Enum.map(raw_providers, fn {name, overrides} ->
      base = Map.get(presets, name, %ProviderConfig{api_base: "", model: ""})
      merged = apply_overrides(base, overrides)

      with :ok <- validate_provider(merged) do
        {name, merged}
      else
        {:error, reason} -> raise "Invalid provider config for '#{name}': #{reason}"
      end
    end)
    |> Map.new()
  end

  defp validate_provider(%ProviderConfig{api_base: api_base, model: model}) do
    errors = []

    errors =
      if is_binary(api_base) and api_base != "" do
        errors
      else
        ["api_base must be a non-empty string" | errors]
      end

    errors =
      if is_binary(model) and model != "" do
        errors
      else
        ["model must be a non-empty string" | errors]
      end

    if errors == [], do: :ok, else: {:error, Enum.join(errors, ", ")}
  end

  defp apply_overrides(%ProviderConfig{} = base, overrides) when is_map(overrides) do
    %ProviderConfig{
      api_base: Map.get(overrides, "api_base", base.api_base),
      model: Map.get(overrides, "model", base.model),
      api_key_env: Map.get(overrides, "api_key_env", base.api_key_env),
      native: Map.get(overrides, "native", base.native),
      auth_method:
        case Map.get(overrides, "auth_method") do
          "device" -> :device
          _ -> base.auth_method
        end
    }
  end

  defp apply_overrides(base, _overrides), do: base

  defp build_memory(raw) do
    %MemoryConfig{
      enabled: Map.get(raw, "enabled", true),
      db_path: Map.get(raw, "db_path", "~/.musician/memory.db"),
      nudge_interval_minutes: Map.get(raw, "nudge_interval_minutes", 30)
    }
  end

  defp build_skills(raw) do
    %SkillsConfig{
      directory: Map.get(raw, "directory", "~/.musician/skills/"),
      auto_create: Map.get(raw, "auto_create", true),
      self_improve: Map.get(raw, "self_improve", true)
    }
  end

  defp build_session(raw) do
    %SessionConfig{
      history_file: Map.get(raw, "history_file", "~/.musician/history.jsonl"),
      max_entries: Map.get(raw, "max_entries", 500)
    }
  end

  defp build_tui(raw) do
    %TuiConfig{
      theme: Map.get(raw, "theme", "default"),
      vim_mode: Map.get(raw, "vim_mode", false),
      show_token_count: Map.get(raw, "show_token_count", true)
    }
  end
end
