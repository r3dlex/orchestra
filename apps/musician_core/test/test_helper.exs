ExUnit.start()
Mox.defmock(MusicianCore.HTTPMock, for: MusicianCore.HTTP)
Mox.defmock(MusicianCore.TokenStoreMock, for: MusicianCore.TokenStore)

# Start the Mox GenServer for Mox 1.2.0.
# Returns {:ok, pid} or :ignore (already started).
case Mox.start_link_ownership() do
  {:ok, _} -> :ok
  :ignore -> :ok
  other -> raise "Mox.start_link_ownership failed: #{inspect(other)}"
end
