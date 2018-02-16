-module(main).
-author("vkutovoi").

%% API
-export([run/3]).



run(Method, Path, Body) ->
  Res = validate:run(Method, Path, Body),
  db_main:run(Method, Path, Res).
