-module(db_worker).
-author("vkutovoi").

-behaviour(gen_server).

%% API
-export([start_link/1]).

%% gen_server callbacks
-export([init/1,
  handle_call/3,
  handle_cast/2,
  handle_info/2,
  terminate/2,
  code_change/3]).

-define(SERVER, ?MODULE).

-record(state, {conn, monitor}).


start_link(DbConfig) ->
  gen_server:start_link(?MODULE, DbConfig, []).

init(DbConfig) ->
  process_flag(trap_exit, true),
  Hostname = proplists:get_value(hostname, DbConfig),
  Database = proplists:get_value(database, DbConfig),
  Username = proplists:get_value(username, DbConfig),
  Password = proplists:get_value(password, DbConfig),
  {ok, Pid} = epgsql:connect(Hostname, Username, Password, [
    {database, Database}
  ]),
  MonitorRef = monitor(process, Pid),
  log:debug("{db_worker_init} connect to Db pid ~p monitor ~p~n", [Pid, MonitorRef]),
  {ok, #state{conn=Pid, monitor = MonitorRef}}.


handle_call({squery, Sql}, _From, #state{conn=Conn}=State) ->
  {reply, epgsql:squery(Conn, Sql), State};
handle_call({equery, Stmt, Params}, _From, #state{conn=Conn}=State) ->
  {reply, epgsql:equery(Conn, Stmt, Params), State};
handle_call(_Request, _From, State) ->
  {reply, ok, State}.

handle_cast(_Request, State) ->
  {noreply, State}.


handle_info({'EXIT', _Pid, Reason}, State) ->
  {stop, Reason, State};

handle_info(Info, State) ->
  log:info("{db_worker_handle_info} unknown msg ~p - ", [Info]),
  {noreply, State}.

terminate(_Reason, State) ->
  demonitor(State#state.monitor, [flush]),
  epgsql:close(State#state.conn),
  ok.


code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

