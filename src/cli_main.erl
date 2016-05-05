-module(cli_main).

-export([main/3, main_error/1, main_error/2]).

-define(ok_exit, 0).
-define(error_exit, 1).

main(Args, Parser, Handler) ->
    handle_main_parse_args(cli:parse_args(Args, Parser), Handler).

handle_main_parse_args({{ok, print_help}, P}, _) ->
    print_help(P);
handle_main_parse_args({{ok, print_version}, P}, _) ->
    print_version(P);
handle_main_parse_args({{ok, Parsed}, P}, Handle) ->
    handle_parsed(Parsed, Handle, P);
handle_main_parse_args({{error, Err}, P}, _) ->
    print_error(Err, P).

print_help(P) ->
    cli:print_help(P),
    ?ok_exit.

print_version(P) ->
    cli:print_version(P),
    ?ok_exit.

print_error(Err, P) ->
    cli:print_error(Err, P),
    ?error_exit.

handle_parsed(Parsed, Handler, P) ->
    Result = (catch call_handler(Handler, Parsed)),
    maybe_print_error(Result, P),
    to_exit_code(Result).

call_handler(F, Args) when is_function(F) ->
    F(Args);
call_handler({M, F, A}, Args) ->
    apply(M, F, [Args|A]).

maybe_print_error({error, {N, Err}}, P) when is_integer(N) ->
    cli_help:print_error(Err, P);
maybe_print_error(_, _) ->
    ok.

to_exit_code(ok)                                    -> ?ok_exit;
to_exit_code({ok, N}) when is_integer(N)            -> N;
to_exit_code(error)                                 -> ?error_exit;
to_exit_code({error, N}) when is_integer(N)         -> N;
to_exit_code({error, {N, _Msg}}) when is_integer(N) -> N.

main_error(Msg) ->
    throw({error, {?error_exit, Msg}}).

main_error(ExitCode, Msg) ->
    throw({error, {ExitCode, Msg}}).
