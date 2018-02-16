-module(log).
-author("vkutovoi").

%% API
-export([
  info/2,
  debug/2,
  error/2,
  warning/2
]).


info(Msg, Body) -> lager:info(Msg, Body).
debug(Msg, Body) -> lager:debug(Msg, Body).
error(Msg, Body) -> lager:error(Msg, Body).
warning(Msg, Body) -> lager:warning(Msg, Body).