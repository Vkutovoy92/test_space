-author("vkutovoi").


-define(IncorrectPath, {invalid_validate, #{
  <<"result">> => <<"error">>,
  <<"reason">> => <<"incorrect path">>
}}).

-define(IncorrectMethod, {invalid_validate, #{
  <<"result">> => <<"error">>,
  <<"reason">> => <<"incorrect method">>
}}).

-define(IncorrectBody, {invalid_validate, #{
  <<"result">> => <<"error">>,
  <<"reason">> => <<"incorrect body">>
}}).

-define(IncorrectBodyOrPath, {invalid_validate, #{
  <<"result">> => <<"error">>,
  <<"reason">> => <<"incorrect body/path">>
}}).

-define(ErrorInsertData(Reason), #{
  <<"result">> => <<"error">>,
  <<"reason">> => Reason}).

-define(ErrorUpdateData(Reason), #{
  <<"result">> => <<"error">>,
  <<"reason">> => Reason}).

-define(ErrorGetData(Reason), #{
  <<"result">> => <<"error">>,
  <<"reason">> => Reason}).