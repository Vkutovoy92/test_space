-module(exomler_dom_decoder).

%% API
-export([decode_prolog/2]).
-export([decode/2]).

-include("exomler.hrl").

%% API
decode_prolog(Bin, Opts) when is_binary(Bin) ->
    case decode_prolog(Bin) of
        {<<>>, _Bin} ->
            {error, no_prolog};
        {Prolog, _Rest} ->
            Format   = exomler:get_value(return, Opts),
            Attrs    = decode_tag_attrs(Prolog, Opts),
            Version  = get_version(Attrs),
            Encoding = get_encoding(Attrs),
            meta(Format, Version, Encoding)
    end;
decode_prolog(Filename, Opts) when is_list(Filename) ->
    case file:read_file(Filename) of
        {ok, Bin}   -> decode_prolog(Bin, Opts);
        Err         -> Err
    end.


decode(Bin, Opts) when is_binary(Bin) ->
    {_, Rest1} = decode_prolog(Bin),
    Rest2 = skip_doctype(exomler_bstring:trim_left(Rest1)),
    {Tag, _Rest} = decode_tag(exomler_bstring:trim_left(Rest2), Opts),
    Tag;
decode(Filename, Opts) when is_list(Filename) ->
    case file:read_file(Filename) of
        {ok, Bin}   -> decode(Bin, Opts);
        Err         -> Err
    end.


%% internal
decode_prolog(<<"<?xml", Bin/binary>>) ->
    exomler_bstring:split(Bin, <<"?>">>);
decode_prolog(Bin) ->
    {<<>>, Bin}.

meta(map, Version, Encoding) ->
    #{
        document    => xml,
        version     => Version,
        encoding    => Encoding
    };
meta(_, Version, Encoding) ->
    {xml, Version, Encoding}.

get_version(Attrs) ->
    case exomler:get_value(<<"version">>, Attrs) of
        <<"1.0">> -> '1.0';
        <<"1.1">> -> '1.1';
        _         -> undefined
    end.

get_encoding(Attrs) ->
    Encoding = exomler:get_value(<<"encoding">>, Attrs),
    Encoding2 = exomler_bstring:to_lower(Encoding),
    case Encoding2 of
        <<"iso-8859-1">>    -> latin1;
        <<"iso_8859_1">>    -> latin1;
        <<"iso_8859-1">>    -> latin1;
        <<"iso8859-1">>     -> latin1;
        <<"utf-8">>         -> utf8;
        <<"utf_8">>         -> utf8;
        <<"utf8">>          -> utf8;
        <<>>                -> undefined;
        _                   -> unknown
    end.

skip_doctype(<<"<!", Bin/binary>>) ->
    {_, Rest} = exomler_bstring:split(Bin, <<">">>),
    Rest;
skip_doctype(Bin) ->
    Bin.

decode_tag(<<"<", Bin/binary>>, Opts) ->
    {TagHeader1, Rest1} = exomler_bstring:split(Bin, <<">">>),
    Len = size(TagHeader1)-1,
    case TagHeader1 of
        <<TagHeader:Len/binary, "/">> ->
            {Tag, Attrs} = decode_tag_header(TagHeader, Opts),
            {{Tag, Attrs,[]}, Rest1};
        TagHeader ->
            {Tag, Attrs} = decode_tag_header(TagHeader, Opts),
            {Content, Rest2} = decode_tag_content(Rest1, Tag, Opts),
            {{Tag, Attrs, Content}, Rest2}
  end.

decode_tag_header(Bin, Opts) ->
    {Tag, Rest} = exomler_bstring:split(Bin, <<" ">>),
    {Tag, decode_tag_attrs(Rest, Opts)}.

decode_tag_attrs(<<>>, Opts) ->
    case exomler:get_value(attributes, Opts, proplist) of
        map -> #{};
        _   -> []
    end;
decode_tag_attrs(<<Blank, Bin/binary>>, Opts) when ?IS_BLANK(Blank) ->
    decode_tag_attrs(Bin, Opts);
decode_tag_attrs(Bin, Opts) ->
    {Key, Value1} = exomler_bstring:split(Bin, <<"=">>),
    {Value2, Rest} = attr_value(Value1),
    case exomler:get_value(attributes, Opts, proplist) of
        map ->
            Map = decode_tag_attrs(Rest, Opts),
            Key2 = exomler_bstring:trim_right(Key),
            Value3 = unescape(Value2),
            maps:put(Key2, Value3, Map);
        _ ->
            Proplist = decode_tag_attrs(Rest, Opts),
            Key2 = exomler_bstring:trim_right(Key),
            Value3 = unescape(Value2),
            [{Key2, Value3}|Proplist]
    end.

attr_value(<<Blank, Bin/binary>>) when ?IS_BLANK(Blank) ->
    attr_value(Bin);
attr_value(<<Quote, Value/binary>>) when ?IS_QUOTE(Quote) ->
    exomler_bstring:split(Value, <<Quote>>).

decode_tag_content(<<"<![CDATA[", Bin/binary>>, Tag, Opts) ->
    {Text, Rest1} = exomler_bstring:split(Bin, <<"]]>">>),
    {Content, Rest2} = decode_tag_content(Rest1, Tag, Opts),
    {[Text|Content], Rest2};
decode_tag_content(<<"<!--", Bin/binary>>, Tag, Opts) ->
    {_Comment, Rest1} = exomler_bstring:split(Bin, <<"-->">>),
    decode_tag_content(Rest1, Tag, Opts);
decode_tag_content(<<"</", Bin/binary>>, Tag, _Opts) ->
    Len = size(Tag),
    <<Tag:Len/binary, Rest1/binary>> = Bin,
    <<">", Rest2/binary>> = exomler_bstring:trim_left(Rest1),
    {[], Rest2};
decode_tag_content(<<"<", _/binary>> = Bin, Tag, Opts) ->
    {TagData, Rest1} = decode_tag(Bin, Opts),
    {Content, Rest2} = decode_tag_content(Rest1, Tag, Opts),
    {[TagData|Content], Rest2};
decode_tag_content(<<Blank, Bin/binary>>, Tag, Opts) when ?IS_BLANK(Blank) ->
    decode_tag_content(Bin, Tag, Opts);
decode_tag_content(Bin, Tag, Opts) ->
    {A, _} = binary:match(Bin, <<"<">>),
    <<Text:A/binary, Rest1/binary>> = Bin,
    {Content, Rest2} = decode_tag_content(Rest1, Tag, Opts),
    {[exomler_bstring:trim_right(unescape(Text))|Content], Rest2}.

unescape(Bin) ->
    case exomler_bstring:split(Bin, <<"&">>) of
        {Unescaped, <<>>} ->
            Unescaped;
        {Unescaped, Rest} ->
            {Char, Rest2} = unescape_char(Rest),
            <<Unescaped/binary, Char/binary, (unescape(Rest2))/binary>>
    end.

unescape_char(<<"quot;", Rest/binary>>) ->
    {<<"\"">>, Rest};
unescape_char(<<"apos;", Rest/binary>>) ->
    {<<"'">>, Rest};
unescape_char(<<"lt;", Rest/binary>>) ->
    {<<"<">>, Rest};
unescape_char(<<"gt;", Rest/binary>>) ->
    {<<">">>, Rest};
unescape_char(<<"amp;", Rest/binary>>) ->
    {<<"&">>, Rest};
unescape_char(<<"#", Rest1/binary>>) ->
    {Num, Rest2} = exomler_bstring:split(Rest1, <<";">>),
    try binary_to_integer(Num) of
        Char -> {<<Char/utf8>>, Rest2}
    catch
        _:_ ->  {<<>>, Rest2}
    end;
unescape_char(Rest1) ->
    {Unknown, Rest2} = exomler_bstring:split(Rest1, <<";">>),
    {<<"&", Unknown/binary, ";">>, Rest2}.



%% Tests
-ifdef(TEST).

-include_lib("eunit/include/eunit.hrl").

decode_document_test_() ->
    [
    ?_assertEqual({xml, '1.0', utf8},
        decode_prolog(<<"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<html></html>\n">>, #{return => tuple}))
    ].

decode_tag_test_() ->
    [
    ?_assertEqual({<<"html">>, [], []},
        decode(<<"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<html></html>\n">>, #{})),
    ?_assertEqual({<<"html">>, [], []},
        decode(<<"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<!DOCTYPE some_dtd SYSTEM \"example.dtd\">\n<html></html>\n">>, #{})),
    ?_assertEqual({<<"html">>, [], []},
        decode(<<"\n<html></html>\n">>, #{})),
    ?_assertEqual({<<"html">>, [], []},
        decode(<<"<html ></html>\n">>, #{})),
    ?_assertEqual({<<"html">>, [], []},
        decode(<<"<html ></html >\n">>, #{})),
    ?_assertEqual({<<"html">>, [], []},
        decode(<<"<html/>\n">>, #{})),
    ?_assertEqual({<<"html">>, [], []},
        decode(<<"\n<html />\n">>, #{}))
    ].

decode_content_test_() ->
    [
    ?_assertEqual({<<"html">>, [], [<<"Body">>]},
        decode(<<"<html >Body</html>\n">>, #{})),
    ?_assertEqual({<<"html">>, [], [{<<"head">>, [], []}]},
        decode(<<"<html><head></head></html>\n">>, #{})),
    ?_assertEqual({<<"html">>, [], [<<"TextBefore">>, {<<"head">>, [], []}, <<"TextAfter">>]},
        decode(<<"<html >TextBefore<head></head>TextAfter</html>\n">>, #{})),
    ?_assertEqual({<<"html">>, [], [<<"TextBefore">>, {<<"head">>, [], []}, <<"TextAfter">>]},
        decode(<<"<html > \nTextBefore<head></head>TextAfter</html>\n">>, #{})),
    ?_assertEqual({<<"html">>, [], [{<<"p">>, [], [<<"0 < 5 > 3 & \"5\"='5'">>]}]},
        decode(<<"<html><p> 0 &lt; 5 &gt; 3 &amp; &quot;5&quot;=&apos;5&apos; </p></html>\n">>, #{})),
    ?_assertEqual({<<"html">>, [], [{<<"p">>, [], [<<" 0 < 5 > 3 & \"5\"='5'  ">>]}]},
        decode(<<"<html><p><![CDATA[ 0 < 5 > 3 & \"5\"='5'  ]]></p></html>\n">>, #{})),
    ?_assertEqual({<<"html">>, [], [{<<"p">>, [], [<<"TextBefore">>, <<"TextAfter">>]}]},
        decode(<<"<html><p>TextBefore<!-- Comment -->TextAfter</p></html>\n">>, #{}))
    ].

decode_attributes_test_() ->
    [
    ?_assertEqual({<<"html">>, [{<<"xmlns">>,<<"w3c">>}], []},
        decode(<<"<html xmlns=\"w3c\"></html>\n">>, #{})),
    ?_assertEqual({<<"html">>, [{<<"xmlns">>,<<"w3c">>}], []},
        decode(<<"<html xmlns=\"w3c\" ></html>\n">>, #{})),
    ?_assertEqual({<<"html">>, [{<<"xmlns">>,<<"w3c">>}], []},
        decode(<<"<html xmlns='w3c' />\n">>, #{})),
    ?_assertEqual({<<"html">>, [{<<"k">>,<<"v">>}], []},
        decode(<<"<html k=\"v\"/>\n">>, #{})),
    ?_assertEqual({<<"html">>, [{<<"k">>,<<"v">>}], []},
        decode(<<"<html k=\"v\" />\n">>, #{})),
    ?_assertEqual({<<"html">>, [{<<"k">>,<<"v">>}], []},
        decode(<<"<html k  =  \"v\" />\n">>, #{})),
    ?_assertEqual({<<"html">>, [{<<"k">>,<<" 0 < 1 ">>}], []},
        decode(<<"<html k  =  \" 0 &lt; 1 \" />\n">>, #{}))
  ].

-endif.
