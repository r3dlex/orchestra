defmodule Orchestra.Backends.Registry do
  @moduledoc "Detect available worker backends (musician, claude, codex, gemini)."

  @backends [:musician, :claude, :codex, :gemini]

  def detect do
    paths =
      Enum.map(@backends, fn name ->
        {name, System.find_executable(Atom.to_string(name))}
      end)

    detect_with(paths)
  end

  def detect_with(paths) do
    found = Enum.filter(paths, fn {_name, path} -> path != nil end)
    if found == [], do: {:error, :no_backends}, else: {:ok, found}
  end
end
