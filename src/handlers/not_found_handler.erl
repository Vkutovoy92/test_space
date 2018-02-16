-module(not_found_handler).
-author("vkutovoi").

%% API
-export([init/2]).

-include("errors_codes.hrl").

init(Req, State) ->
  Res = cowboy_req:reply(
    400,
    #{<<"content-type">> => <<"application/json">>},
    jiffy:encode(?IncorrectPath),
    Req),
  {ok, Res, State}.
