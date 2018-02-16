-module(db_sup).
-author("vkutovoi").

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).


start_link() ->
  supervisor:start_link({local, ?SERVER}, ?MODULE, []).


init([]) ->

  {ok, Pools}  = application:get_env(test_quest, db_pools),

  PoolSpecs = lists:map(fun({Name, SizeArgs, WorkerArgs}) ->
    PoolArgs = [{name, {local, Name}}, {worker_module, db_worker}] ++ SizeArgs,

    poolboy:child_spec(Name, PoolArgs, WorkerArgs)
                        end, Pools),

  {ok, {{one_for_one, 10, 10}, PoolSpecs}}.


