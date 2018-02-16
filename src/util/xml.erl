-module(xml).

-author("vkutovoi").

-export([xml_to_list/1, move_attrs/1, build_xml_attr/2, build_xml_val/2, form_tag_val/1]).

%% --------------- ��������� xml � list ------------------ %%
%% ------------------------------------------------------- %%
xml_to_list(XML) ->
  try
    List = exomler:decode(XML),
    {ok, List}
  catch
    _:Reason -> Reason
  end.
%% --------------- ��������� list � xml ------------------ %%
%% ------------------------------------------------------- %%

% Tree to proplists
move_attrs(Data) when is_binary(Data) ->
  Data;
move_attrs(Data) when is_list(Data) ->
  move_attrs(Data, [], list);

move_attrs({Key, [{KeyAttr, ValAttr} |[]], []}) ->
  {Key, [{KeyAttr, ValAttr}, {<<"#text">>, <<>>}]};
move_attrs({Key, [{KeyAttr, ValAttr} | T], []}) ->
  move_attrs({Key, T, [{<<"#text">>, <<>>}, {KeyAttr, ValAttr}]});
move_attrs({Key, [{KeyAttr, ValAttr} | T], Values}) when is_list(Values) ->
  move_attrs({Key, T, [{KeyAttr, ValAttr} | Values]});
move_attrs({Key, [{KeyAttr, ValAttr} | T], Values}) ->
  move_attrs({Key, T, [{KeyAttr, ValAttr}, Values]});
move_attrs({Key, [], []})  ->
  {Key, [{<<"#text">>, <<>>}]};
move_attrs({Key, [], Values}) when is_list(Values)  ->
  {Key, lists:reverse(move_attrs(Values, []))};
move_attrs({Key, [], Values})  ->
  {Key, Values}.

move_attrs([{_Key, _Attrs, _Values} = H | T], Result) ->
  move_attrs(T, [move_attrs(H) | Result]);

move_attrs([{_Key, _Value} = H | T], Result) ->
  move_attrs(T, [H | Result]);
move_attrs([XmlValue], Result) ->
  [{<<"#text">>, XmlValue} | Result];
move_attrs([], Result) ->
  merge_values(Result).

move_attrs([H | T], Result, list) ->
  move_attrs(T, [move_attrs(H) | Result], list);

move_attrs([], Result, list) ->
  merge_values(Result).

merge_values(Values) ->
  merge_values(Values, []).

merge_values([{Key, _Value} = H | T] = Values, Result) ->
  case proplists:get_all_values(Key, Values) of
    [_] ->
      merge_values(T, [H | Result]);
    _ ->
      Rest = proplists:delete(Key, Values),
      merge_values(Rest, [{Key, lists:reverse(proplists:get_all_values(Key, Values))} | Result])
  end;

merge_values([], Result) ->
  lists:reverse(Result).

%% Dynamic build Tag XML
build_xml_attr({Tag, Type, AttrFields}, Data) ->
  F = fun(Key, Acc) ->
    case lists:keyfind(Key, 1, Data) of
      false ->
        Acc;
      {_, Val} ->
        <<Acc/binary, Key/binary, <<"='">>/binary, Val/binary, <<"' ">>/binary >>
    end
      end,
  Attrs = lists:foldl(F, <<>>, AttrFields),
  complete_tag_as_attrs(Tag, Type, Attrs).

build_xml_val({Tag, Field}, Data) ->
  Val = proplists:get_value(Field, Data, <<>>),
  complete_tag_as_val(Tag, Val).

complete_tag_as_val(Tag, Val) ->
  <<
    <<"<">>/binary, Tag/binary, <<">">>/binary,
    Val/binary,
    <<"</">>/binary, Tag/binary, <<">">>/binary
  >>.

complete_tag_as_attrs(Tag, default_close, Attrs) ->
  <<
    <<"<">>/binary, Tag/binary, <<" ">>/binary,
    Attrs/binary, <<">">>/binary,
    <<"</">>/binary, Tag/binary, <<">">>/binary
  >>;
complete_tag_as_attrs(Tag, inline_close, Attrs) ->
  <<
    <<"<">>/binary, Tag/binary, <<" ">>/binary,
    Attrs/binary,
    <<"/>">>/binary
  >>.

form_tag_val(L) ->
  form_acc(L,<<>>).

form_acc([], Acc) ->
  Acc;
form_acc([{Tag,Val}|T], <<>>) ->
  form_acc(T, << <<"<">>/binary, Tag/binary, <<">">>/binary,
    Val/binary, <<"</">>/binary, Tag/binary, <<">">>/binary>> );

form_acc([{Tag,Val}|T],Acc) ->
  form_acc(T, <<  <<"<">>/binary, Tag/binary, <<">">>/binary,
    Val/binary, <<"</">>/binary, Tag/binary, <<">">>/binary, Acc/binary >>).