#!/usr/bin/env escript
%%! -noshell

main(_) ->
    {ok, Files} = file:list_dir("_build/test"),
    CoverdataFiles = lists:filter(
        fun(F) ->
            filelib:is_file(filename:join(["_build/test", F])) andalso
            ".coverdata" == filename:extension(F)
        end,
        Files
    ),
    io:format("Found ~p coverdata files~n", [length(CoverdataFiles)]),
    cover:start(),
    [cover:import(filename:join(["_build/test", F])) || F <- CoverdataFiles],
    file:make_dir("_build/coverage"),
    cover:write_file("_build/coverage/coverage.xml"),
    io:format("Coverage report written to _build/coverage/coverage.xml~n"),
    init:stop(),
    ok.
