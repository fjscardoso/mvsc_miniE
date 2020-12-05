-module(supv).

-compile(export_all).
 
start(Mod,Args) ->
	register(?MODULE, Pid = spawn_link(?MODULE, init, [{Mod, Args}])),
		Pid.

init({Mod,Args}) ->
	process_flag(trap_exit, true),
	start({Mod,Args}).
 
start({M,A}) ->
	Server = apply(M,start_link,A),
	recieving(Server, {M,A}).

recieving(Server,{M,A}) ->
	receive
		{where, Ref,From} -> From ! {Ref, Server},
			recieving(Server, {M,A});
		{'EXIT', _From, shutdown} ->
			exit(shutdown); % will kill the child too
		{'EXIT', Pid, Reason} ->
			io:format("Process ~p exited for reason ~p~n",[Pid,Reason]),
			start({M,A})	
end.
