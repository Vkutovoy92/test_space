-module(db_main).
-author("vkutovoi").

%% API
-export([run/3, equery/3]).

-define(PoolName, pool1).

-include("errors_codes.hrl").

run(<<"POST">>, _, {ok, DecodeBody}) ->
  Query = "insert into news (body_news) values ($1) returning id;",
  case equery(?PoolName, Query, [DecodeBody]) of
    {ok, _,[{column,<<"id">>,_, _, _, _}],[{Id}]} ->
      #{<<"result">> => <<"success">>, <<"id">> => Id};
    {error,{error,error, _, unique_violation, _, _}} ->
      ?ErrorInsertData(<<"news already exists">>);
    Any ->
      log:error("{db_main_run} cannot insert news ~p", [Any]),
      ?ErrorInsertData(<<"unknown error">>)
  end;

run(<<"PUT">>, [IdNews], {ok, DecodeBody}) ->
  Query = "update news set body_news = $1 where id = $2;",
  case equery(?PoolName, Query, [DecodeBody, binary_to_integer(IdNews)]) of
    {ok, 1} ->
      #{<<"result">> => <<"success">>};
    {ok,0} ->
      ?ErrorUpdateData(<<"id not found">>);
    Any ->
      log:error("{db_main_run} cannot update news ~p", [Any]),
      ?ErrorUpdateData(<<"unknown error">>)
  end;

run(<<"GET">>, [IdNews], _) ->
  Query = "select body_news from news where id = $1;",
  case equery(?PoolName, Query, [binary_to_integer(IdNews)]) of
    {ok, _,[{Data}]} ->
      #{<<"result">> => <<"success">>, <<"body">> => Data};
    {ok, _, []} ->
      ?ErrorGetData(<<"not body for this id">>);
    Any ->
      log:error("{db_main_run} cannot get news ~p", [Any]),
      ?ErrorGetData(<<"unknown error">>)
  end;

run(<<"DELETE">>, [IdNews], _) ->
  Query = "delete from news where id = $1;",
  case equery(?PoolName, Query, [binary_to_integer(IdNews)]) of
    {ok, 1} ->
      #{<<"result">> => <<"success">>};
    {ok, 0} ->
      ?ErrorGetData(<<"not body for this id ib db">>);
    Any ->
      log:error("{db_main_run} cannot delete news ~p", [Any]),
      ?ErrorGetData(<<"unknown error">>)
  end.



equery(PoolName, Stmt, Params) ->
  poolboy:transaction(PoolName, fun(Worker) ->
    gen_server:call(Worker, {equery, Stmt, Params})
                                end).