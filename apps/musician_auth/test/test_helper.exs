ExUnit.start()

# Start Bypass (a Supervisor-based OTP app) for HTTP mocking in tests.
{:ok, _} = Application.ensure_all_started(:bypass)
