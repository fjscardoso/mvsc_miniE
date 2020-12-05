-module(consumer).

-compile(export_all).

start(Server, Num) ->
	spawn_link(?MODULE, init, [Server, Num]).

init(Server, Num) ->
	Ref = erlang:monitor(process, Server),
	consume(Server, Ref, Num).

consume(_,_, 0) -> ok;
consume(Server, Ref, Num) ->
	Server ! {remove, Ref, self()},
	receive 
		{removed, _Rem, Ref} -> 
			consume(Server,Ref,Num-1);
		{'DOWN', Ref, process, _Pid, _Reason} ->
			error
	end.
