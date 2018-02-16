-module(validate).
-author("vkutovoi").

%% API
-export([run/3]).

-include("errors_codes.hrl").

-define(XSS_REGEXP, <<"&<>'">>).


run(Method, Path, Body) ->
  choose_scheme(Method, length(Path), Body).


choose_scheme(Method,  PathLength, _) when Method == <<"GET">>; Method == <<"DELETE">>->
  if
    PathLength == 1 -> ok;
    true -> throw(?IncorrectPath)
  end;

choose_scheme(<<"POST">>, _, Body)->
  if
    Body =/= <<>> -> check_valid_body(Body);
    true -> throw(?IncorrectBodyOrPath)
  end;
choose_scheme(_Method, PathLength, Body) ->
  if
    PathLength == 1, Body =/= <<>> -> check_valid_body(Body);
    true -> throw(?IncorrectBodyOrPath)
  end.



check_valid_body(Body) ->
  log:debug("Body  ~p", [Body]),
  try
    xml:move_attrs(mochiweb_html:parse(Body))
  of
    FormatData ->
      {ok, jsx:encode([FormatData])}
  catch
      _:ErrorReason  ->
        log:error("{validate_check_valid_body} ~p", [ErrorReason]),
        throw(?IncorrectBody)
  end.




