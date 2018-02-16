%%%-------------------------------------------------------------------
%% @doc test_project public API
%% @end
%%%-------------------------------------------------------------------

-module(test_project_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%%====================================================================
%% API
%%====================================================================

start(_StartType, _StartArgs) ->
    start_web_server(),
    test_project_sup:start_link().

%%--------------------------------------------------------------------
stop(_State) ->
    ok.

%%====================================================================
%% Internal functions
%%====================================================================
start_web_server() ->
    Dispatch = cowboy_router:compile([
        {'_', [
            {"/api/[...]",      http_handler, []},
            {'_',               not_found_handler, []}
        ]}
    ]),

    {ok, Config}  = application:get_env(test_project, web_server),

    Port          = proplists:get_value(port,            Config),
    MaxConnection = proplists:get_value(max_connections, Config),
    TransOpts = [{port, Port}, {max_connections, MaxConnection}],

    {ok, _Res} = cowboy:start_clear(http, TransOpts, #{
        env => #{dispatch => Dispatch}
    }),
    lager:info("[http_listener] http://localhost:" ++ integer_to_list(Port), []).


