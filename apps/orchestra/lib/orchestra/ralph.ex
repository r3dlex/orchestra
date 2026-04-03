defmodule Orchestra.Ralph do
  @moduledoc "Persistence loop: retry until verified or max_retries exhausted."

  @default_max_retries 10

  def run(task, opts \\ []) do
    verifier = Keyword.get(opts, :verifier, fn _state -> :pass end)
    max_retries = Keyword.get(opts, :max_retries, @default_max_retries)
    state = %{task: task, attempts: 0}
    loop(state, verifier, max_retries)
  end

  defp loop(state, verifier, max_retries) do
    if state.attempts >= max_retries do
      {:error, :max_retries}
    else
      state = Map.update!(state, :attempts, &(&1 + 1))

      case verifier.(state) do
        :pass -> {:ok, :done}
        :fail -> loop(state, verifier, max_retries)
      end
    end
  end
end
