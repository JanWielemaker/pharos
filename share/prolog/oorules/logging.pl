% ============================================================================================
% Debugging and printing.
% ============================================================================================

:- format_predicate('P', format_write_hex(_, _)).
:- format_predicate('Q', format_write_hex_quoted(_, _)).
:- dynamic(logLevel/1).
:- use_module(library(option), [merge_options/3]).

% Convenience methods, since it's easier to type the lowercase predicate name.
logfatal(X) :- baselog('FATAL', X).
logerror(X) :- baselog('ERROR', X).
logwarn(X)  :- baselog('WARN', X).
loginfo(X)  :- baselog('INFO', X).
logdebug(X) :- baselog('DEBUG', X).
logtrace(X) :- baselog('TRACE', X).
logcrazy(X) :- baselog('CRAZY', X).

logfatal(Cond, Fmt, Args) :- fmtlog(Cond, 'FATAL', Fmt, Args).
logerror(Cond, Fmt, Args) :- fmtlog(Cond, 'ERROR', Fmt, Args).
logwarn(Cond, Fmt, Args)  :- fmtlog(Cond, 'WARN', Fmt, Args).
loginfo(Cond, Fmt, Args)  :- fmtlog(Cond, 'INFO', Fmt, Args).
logdebug(Cond, Fmt, Args) :- fmtlog(Cond, 'DEBUG', Fmt, Args).
logtrace(Cond, Fmt, Args) :- fmtlog(Cond, 'TRACE', Fmt, Args).
logcrazy(Cond, Fmt, Args) :- fmtlog(Cond, 'CRAZY', Fmt, Args).

logfatalln(X) :- baselogln('FATAL', X).
logerrorln(X) :- baselogln('ERROR', X).
logwarnln(X)  :- baselogln('WARN', X).
loginfoln(X)  :- baselogln('INFO', X).
logdebugln(X) :- baselogln('DEBUG', X).
logtraceln(X) :- baselogln('TRACE', X).
logcrazyln(X) :- baselogln('CRAZY', X).

logfatalln(Cond, Fmt, Args) :- fmtlogln(Cond, 'FATAL', Fmt, Args).
logerrorln(Cond, Fmt, Args) :- fmtlogln(Cond, 'ERROR', Fmt, Args).
logwarnln(Cond, Fmt, Args)  :- fmtlogln(Cond, 'WARN', Fmt, Args).
loginfoln(Cond, Fmt, Args)  :- fmtlogln(Cond, 'INFO', Fmt, Args).
logdebugln(Cond, Fmt, Args) :- fmtlogln(Cond, 'DEBUG', Fmt, Args).
logtraceln(Cond, Fmt, Args) :- fmtlogln(Cond, 'TRACE', Fmt, Args).
logcrazyln(Cond, Fmt, Args) :- fmtlogln(Cond, 'CRAZY', Fmt, Args).

% Associate log level strings with numbers.  Perhaps we should alter the C++ API?
numericLogLevel('FATAL', 1).
numericLogLevel('ERROR', 2).
numericLogLevel('WARN', 3).
numericLogLevel('INFO', 4).
numericLogLevel('DEBUG', 5).
numericLogLevel('TRACE', 6).
numericLogLevel('CRAZY', 7).

baselog(Level, X) :-
    fmtlog(true, Level, '~P', [X]).
baselogln(Level, X) :-
    fmtlog(true, Level, '~P~n', [X]).

fmtlog(Cond, Level, Fmt, Args) :-
    (call(Cond), format(atom(Repr), Fmt, Args)) -> log(Level, Repr) ; true.
fmtlogln(Cond, Level, Fmt, Args) :-
    (call(Cond), format(atom(Repr), Fmt, Args)) -> logln(Level, Repr) ; true.

% This is a default implementation of traceAtLevel which should never be used because the code
% in goal_expansion/2 below should replace it at load time.
traceAtLevel(_, _) :- throw(system_error).

logLevelEnabled(S) :-
    numericLogLevel(S, OtherLogLevel),
    logLevel(CurrentLogLevel),
    CurrentLogLevel >= OtherLogLevel.

portray_hex(X, _Options) :-
    integer(X),
    (X < 0 -> (Y is X * -1, format('-0x~16r', Y))
    ; (X > 0 -> format('0x~16r', X))).

writeHex(X, Options) :-
    merge_options([portray_goal(portray_hex)], Options, NewOpts),
    write_term(X, NewOpts).

writeHex(X) :-
    writeHex(X, [spacing(next_argument)]).

writeHexQuoted(X) :-
    writeHex(X, [spacing(next_argument), quoted(true)]).

writelnHex(X) :-
    writeHex(X), nl.

% Write to logfatal, logerror, or logwarn instead...
%errwrite(Fmt, Args) :-
%    format(user_error, Fmt, Args).
%errwriteln(Fmt, Args) :-
%    format(user_error, Fmt, Args), nl(user_error).

format_write_hex(_, X) :-
    writeHex(X).

format_write_hex_quoted(_, X) :-
    writeHexQuoted(X).


% Enable compile-time transformations so we can leave very expensive debugging statements in
% the code without incurring a runtime cost.  Because SWI compiles at load time, you can just
% set the logLevel parameter as normal.

%% matches log<Level> and log<Level>ln, returning <Level>
logging_atom(Atom, Level) :-
    sub_atom(Atom, 0, _, _, log),
    ((sub_atom(Atom, _, 2, 0, ln),
      sub_atom(Atom, 3, _, 2, LLevel))
    ; sub_atom(Atom, 3, _, 0, LLevel)),
    upcase_atom(LLevel, Level),
    numericLogLevel(Level, _).

noop(_).

baselogname(log).
baselogname(logln).
baselogname(fmtlog).
baselogname(fmtlogln).

%% Uncomment to check for dangerous logging arguments (that might be lists)
%% goal_expansion(Goal, Layout, _, _) :-
%%     Goal =.. [Name, _Fmt, Args],
%%     var(Args),
%%     logging_atom(Name, _),
%%     format(user_error, "Bad Goal: ~Q~nLocation: ~q~n", [Goal, Layout]),
%%     halt(1).

goal_expansion(Goal, Out) :-
    Goal =.. [Name, Level|_],
    baselogname(Name),
    (logLevelEnabled(Level) -> Out = Goal ; Out = true).

goal_expansion(Goal, Out) :-
    Goal =.. [Name, _Fmt, Args],
    logging_atom(Name, Level),
    (logLevelEnabled(Level) -> Out = Goal ; Out = noop(Args)).

goal_expansion(Goal, Out) :-
    functor(Goal, Name, _),
    logging_atom(Name, Level),
    (logLevelEnabled(Level) -> Out = Goal ; Out = true).

goal_expansion(Goal, Out) :-
    Goal =.. [traceAtLevel, Level, G],
    (logLevelEnabled(Level) -> Out=G; Out=true).

% We originally wrote debug logs with ~@.  Because of annoying reasons, this doesn't play well
% with monotonic tabling.  So we look for calls like logdebugln('~@~Q', [Cond, Blah]) and
% rewrite it to logdebugln(Cond, '~Q', [Blah]) which doesn't have the same issue.

goal_expansion(Goal, Out) :-
    % Goal is logdebugln('~@~Q', [Cond, Foo])
    ((Goal =.. [Name, Fmt, [Cond|OtherArgs]], ExistingCond=true);
     % Goal is logdebugln(ExistingCond, '~@~Q', [NewCond, Foo])
     (Goal =.. [Name, ExistingCond, Fmt, [Cond|OtherArgs]])),

    logging_atom(Name, _Level),
    % Does the format start with ~@?
    sub_string(Fmt, 0, 2, _, '~@'),
    sub_string(Fmt, 2, _, 0, NewFmt),

    Out =.. [Name, (ExistingCond, Cond), NewFmt, OtherArgs].


% Here is a normal rule where we change logdebugln('~P', 42) to logdebugln(true, '~P', 42).
goal_expansion(Goal, Out) :-
    Goal =.. [Name, Fmt, Args],
    logging_atom(Name, _Level),
    Out =.. [Name, true, Fmt, Args].

%% Local Variables:
%% mode: prolog
%% End:
