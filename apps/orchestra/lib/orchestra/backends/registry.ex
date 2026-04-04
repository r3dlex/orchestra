defmodule Orchestra.Backends.Registry do
  @moduledoc "Detect available worker backends (musician, claude, codex, gemini)."

  @backends [:musician, :claude, :codex, :gemini]

  @doc """
  Detects all available backends via System.find_executable/1,
  then filters by user-configured enabled_backends.
  """
  def detect do
    paths =
      Enum.map(@backends, fn name ->
        {name, System.find_executable(Atom.to_string(name))}
      end)

    detect_with(paths)
  end

  def detect_with(paths) do
    found = Enum.filter(paths, fn {_name, path} -> path != nil end)
    enabled = Application.get_env(:orchestra, :enabled_backends, @backends)
    filtered = Enum.filter(found, fn {name, _} -> name in enabled end)

    if filtered == [],
      do: {:error, :no_backends},
      else: {:ok, filtered}
  end

  @doc """
  Returns the preferred backend, with musician as fallback if available.
  """
  def preferred do
    with {:ok, backends} <- detect() do
      musician = List.keyfind(backends, :musician, 0)
      {:ok, musician || hd(backends)}
    end
  end
end
