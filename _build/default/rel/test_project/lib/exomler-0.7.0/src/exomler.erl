-module(exomler).

%% API
-export([decode_prolog/1, decode_prolog/2]).
-export([decode/1, decode/2]).
-export([encode/1, encode/2]).

-export([get_value/2, get_value/3]).

-type xml_text() :: binary().
-type attrs() :: [{binary(), binary()}] | #{binary() => binary()}.
-type content() :: [binary() | xml_ast()].
-type xml_ast() :: {Tag :: binary(), attrs(), content()}.
-type xml_version() :: '1.0' | '1.1'.
-type xml_encoding() :: utf8 | latin1.
-type xml_document() :: {xml, xml_version(), xml_encoding(), xml_ast()}.

%% API
decode_prolog(Bin) ->
    exomler_dom_decoder:decode_prolog(Bin, #{}).

decode_prolog(Bin, Opts) ->
    exomler_dom_decoder:decode_prolog(Bin, Opts).

-spec decode(XML :: xml_text()) -> xml_ast() | xml_document().
decode(XML) ->
    exomler_dom_decoder:decode(XML, #{}).

decode(XML, Opts) ->
    exomler_dom_decoder:decode(XML, Opts).

-spec encode(Ast :: xml_ast()) -> xml_text().
encode(Ast) ->
    exomler_dom_encoder:encode(Ast, #{}).

encode(Ast, Opts) ->
    exomler_dom_encoder:encode(Ast, Opts).

get_value(Key, List) ->
    get_value(Key, List, undefined).

get_value(Key, Map, Default) when is_map(Map) ->
    maps:get(Key, Map, Default);
get_value(Key, List, Default) when is_list(List) ->
    case lists:keyfind(Key, 1, List) of
        {_, Value} ->
            Value;
        _ ->
            case lists:member(Key, List) of
                true -> true;
                false -> Default
            end
    end.
