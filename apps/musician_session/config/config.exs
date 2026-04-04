import Config

config :musician_session,
  history_path: Path.join(System.user_home(), ".musician/history.jsonl"),
  max_entries: 500
