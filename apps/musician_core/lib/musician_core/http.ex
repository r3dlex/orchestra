defmodule MusicianCore.HTTP do
  @moduledoc """
  Thin HTTP client wrapper so Req can be mocked in tests.

  Each function returns the raw Req response map so callers can pattern-match
  on status codes and headers.
  """

  @doc "Performs a POST request with a JSON body."
  @callback post(url :: String.t(), json :: map(), headers :: keyword()) ::
              {:ok, %{status: non_neg_integer(), body: map(), headers: keyword()}}
              | {:error, term()}

  @doc "Performs a streaming POST request. Options are passed directly to Req.post."
  @callback post_streaming(
              url :: String.t(),
              json :: map(),
              headers :: keyword(),
              into :: fun(),
              receive_timeout :: non_neg_integer()
            ) :: :ok

  @doc "Performs a GET request."
  @callback get(url :: String.t(), headers :: keyword()) ::
              {:ok, %{status: non_neg_integer(), body: map(), headers: keyword()}}
              | {:error, term()}

  @behaviour MusicianCore.HTTP

  @impl true
  def post(url, json, headers \\ []) do
    Req.post(url, json: json, headers: headers)
  end

  @impl true
  def post_streaming(url, json, headers, into, receive_timeout) do
    Req.post(url, json: json, headers: headers, into: into, receive_timeout: receive_timeout)
  end

  @impl true
  def get(url, headers \\ []) do
    Req.get(url, headers: headers)
  end
end
