defmodule MusicianCore.E2EHelpers do
  @moduledoc """
  Shared helpers for provider E2E tests.

  HTTP/1.1 connection pools may briefly recycle after a streaming request on the
  same host. `safe_call/1` retries once after a short wait to handle this.
  """

  def safe_call(func) do
    try do
      func.()
    catch
      :exit, _ ->
        :timer.sleep(500)
        func.()
    end
  end

  def start_finch do
    case Finch.start_link(name: Req.Finch) do
      {:ok, pid} ->
        Process.unlink(pid)
        :ok

      {:error, {:already_started, pid}} ->
        Process.unlink(pid)
        :ok
    end
  end
end
