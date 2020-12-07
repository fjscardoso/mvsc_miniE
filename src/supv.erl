-module(supv).

-compile(export_all).


%% The supervisor process will be linked to the server
%% and will trap the server's exit signals.

start(Mod, Args) ->
    register(?MODULE, Pid = spawn_link(?MODULE, init, [{Mod, Args}])),
    Pid.

init({Mod, Args}) ->
    process_flag(trap_exit, true),
    start({Mod, Args}).


%% Create a new instance of the server; start listening for events
start({M, A}) ->
    Server = apply(M, start_link, A),
    receiving(Server, {M, A}).

%% The supervisor will restart the server (if it dies) indefinitely, unless
%% the supervisor itself is terminated with a shutdown exit signal.
%% Additionally, as the pid of the server may change between restarts, the
%% supervisor is also the responsible for informing producers/consumers
%% about the (new) server identifier.
receiving(Server, {M, A}) ->
    receive
        {where, Ref, From} ->
            From ! {Ref, Server},
            receiving(Server, {M, A});
        {'EXIT', _From, shutdown} ->
            exit(shutdown); % will kill the child too
        {'EXIT', Pid, Reason} ->
            io:format("Process ~p exited for reason ~p~n", [Pid, Reason]),
            start({M, A})
    end.
