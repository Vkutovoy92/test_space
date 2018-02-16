%%%-------------------------------------------------------------------
%% @doc test_project top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(test_project_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).

%%====================================================================
%% API functions
%%====================================================================

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%%====================================================================
%% Supervisor callbacks
%%====================================================================

%% Child :: {Id,StartFunc,Restart,Shutdown,Type,Modules}
init([]) ->

    DbSup = {db_sup, {db_sup, start_link, []},
        permanent, 2000, supervisor, [db_sup]},

    {ok, { {one_for_one, 0, 1}, [DbSup]} }.

%%====================================================================
%% Internal functions
%%====================================================================
