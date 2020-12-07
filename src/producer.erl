-module(producer).

-compile(export_all).

start(Supv, Num) ->
    spawn_link(?MODULE, init, [Supv, Num]).


%% Initial state: the producer needs to ask the supervisor for the
%% pid of the server, as it may change if the server is restarted.
%% Once the pid is received, the producer starts monitoring the server,
%% so as to know if it went down - if so, the producer must return to this state.
%% After that, it can start producing.
init(Supv, Num) ->
    AuxRef = make_ref(),
    Supv ! {where, AuxRef, self()},
    receive
        {AuxRef, Server} ->
            Ref = erlang:monitor(process, Server),
            produce(Supv, Server, Ref, Num)
    end.

%% To produce an item, the producer sends an insert request to the server.
%% It then waits for the server response, which indicates the item
%% was indeed added to the buffer.
%% The producer can only send the next insert request after receiving
%% the response for the previous one. This protocol ensures no producer
%% can flood the server's mail box.
produce(_, _, Ref, 0) -> erlang:demonitor(Ref);
produce(Supv, Server, Ref, Num) ->
    Server ! {insert, Num, Ref, self()},
    receive
        {inserted, Num, Ref} ->
            produce(Supv, Server, Ref, Num - 1);
        {'DOWN', Ref, process, _Pid, _Reason} ->
            init(Supv, Num)
    end.
