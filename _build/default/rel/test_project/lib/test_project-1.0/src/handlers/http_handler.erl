-module(http_handler).
-author("vkutovoi").

%% API
-export([init/2]).

-define(Methods, [<<"GET">>, <<"POST">>, <<"PUT">>, <<"DELETE">>]).

-include("errors_codes.hrl").

init(Req = #{method := InputMethod}, State) ->
  Res = case lists:member(InputMethod, ?Methods) of
    true -> handler(Req);
    false ->
      make_resp(400, ?IncorrectMethod, Req)
  end,
  {ok, Res, State}.


handler(Req = #{method := Method}) ->
  Path = cowboy_req:path_info(Req),
  {ok, Body, _Req1} = cowboy_req:read_body(Req),
  case catch main:run(Method, Path, Body) of

    {invalid_validate, ErrorData} -> make_resp(400, ErrorData, Req);

    RespData -> make_resp(200, RespData, Req)

  end.



make_resp(Code, Body, Req) ->
  cowboy_req:reply(
    Code,
    #{<<"content-type">> => <<"application/json">>},
    jsx:encode(Body),
    Req).

