-module(consumer).
-export([start/2, init/2]).


start(Supv, Num) ->
    spawn_link(?MODULE, init, [Supv, Num]).

%% Initial state: the consumer needs to ask the supervisor for the
%% pid of the server, as it may change if the server is restarted.
%% Once the pid is received, the consumer starts monitoring the server,
%% so as to know if it went down - if so, the consumer must return to this state.
%% After that, it can start consuming.
init(Supv, Num) ->
    AuxRef = make_ref(),
    Supv ! {where, AuxRef, self()},
    receive
        {AuxRef, Server} ->
            Ref = erlang:monitor(process, Server),
            consume(Supv, Server, Ref, Num)
    end.

%% To consume an item, the consumer sends a remove request to the server.
%% It then waits for the server response, which indicates an item
%% was indeed removed from the buffer.
%% The consumer can only send the next remove request after receiving
%% the response for the previous one. This protocol ensures no consumer
%% can flood the server's mail box.
consume(_, _, Ref, 0) -> erlang:demonitor(Ref);
consume(Supv, Server, Ref, Num) ->
    Server ! {remove, Ref, self()},
    receive
        {removed, _Rem, Ref} ->
            consume(Supv, Server, Ref, Num - 1);
        {'DOWN', Ref, process, _Pid, _Reason} ->
            init(Supv, Num)
    end.
