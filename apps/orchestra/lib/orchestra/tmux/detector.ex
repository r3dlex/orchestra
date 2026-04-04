defmodule Orchestra.Tmux.Detector do
  @moduledoc "Detect tmux availability and version >= 3.0."

  @min_version {3, 0, 0}

  @doc """
  Returns {:ok, path, version} if tmux >= 3.0 is available,
  or {:error, reason} otherwise.
  """
  def available? do
    case System.find_executable("tmux") do
      nil ->
        {:error, :tmux_not_found}

      path ->
        check_version(path)
    end
  end

  defp check_version(path) do
    case System.cmd("tmux", ["-V"], stderr_to_stdout: true) do
      {output, 0} ->
        version = parse_version(output)

        if version >= @min_version do
          {:ok, path, version}
        else
          {:error, {:tmux_too_old, version}}
        end

      {_, code} ->
        {:error, {:tmux_version_check_failed, code}}
    end
  end

  defp parse_version(output) do
    case Regex.run(~r/tmux (\d+)\.(\d+)\.(\d+)/, output) do
      [_, major, minor, patch] ->
        {String.to_integer(major), String.to_integer(minor), String.to_integer(patch)}

      _ ->
        {0, 0, 0}
    end
  end
end
