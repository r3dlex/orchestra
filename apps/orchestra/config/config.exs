import Config

config :orchestra,
  enabled_backends: [:musician, :claude, :codex, :gemini],
  worktrees_dir: Path.join(System.user_home(), ".musician/worktrees")
