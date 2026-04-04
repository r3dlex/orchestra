defmodule Orchestra.Team.Dispatch do
  @moduledoc "Route tasks to available backends using Registry-backed detection."

  @doc """
  Detects available backends via Registry, then dispatches worker_count workers
  using round-robin distribution.
  Returns {:error, :no_backends} if no backends are available.
  """
  def dispatch_workers(worker_count) do
    case Orchestra.Backends.Registry.detect() do
      {:error, :no_backends} ->
        {:error, :no_backends}

      {:ok, backends} ->
        Enum.map(1..worker_count, fn id ->
          backend = Enum.at(backends, rem(id - 1, length(backends)), hd(backends))
          dispatch(id, backend)
        end)
    end
  end

  defp dispatch(id, backend) do
    %{worker_id: id, backend: backend}
  end
end
