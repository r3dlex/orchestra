# HTTP client mock — implements MusicianCore.HTTP so Mox can mock it.
Mox.defmock(MusicianCore.HTTPMock, for: MusicianCore.HTTP)

# TokenStore mock — implements MusicianCore.TokenStore behaviour.
Mox.defmock(MusicianCore.TokenStoreMock, for: MusicianCore.TokenStore)
