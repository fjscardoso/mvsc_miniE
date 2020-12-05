-module(supv).

-compile(export_all).
 
start(Mod,Args) ->
	register(?MODULE, Pid = spawn_link(?MODULE, init, [{Mod, Args}])),
		Pid.

init({Mod,Args}) ->
	process_flag(trap_exit, true),
	loop({Mod,start_link,Args}).
 
loop({M,F,A}) ->
	Pid = apply(M,F,A),
	receive
		{'EXIT', _From, shutdown} ->
			exit(shutdown); % will kill the child too
		{'EXIT', Pid, Reason} ->
			io:format("Process ~p exited for reason ~p~n",[Pid,Reason]),
			loop({M,F,A})
end.