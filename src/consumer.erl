
-module(consumer).

-compile(export_all).

start(Supv, Num) ->
	spawn_link(?MODULE, init, [Supv, Num]).

init(Supv, Num) ->
	AuxRef = make_ref(),
	Supv ! {where, AuxRef, self()},
	receive
		{AuxRef, Server} -> 
			Ref = erlang:monitor(process, Server),
			consume(Supv, Server, Ref, Num)
	end.

consume(_,_,Ref, 0) -> erlang:demonitor(Ref);
consume(Supv, Server, Ref, Num) ->
	Server ! {remove, Ref, self()},
	receive 
		{removed, _Rem, Ref} -> 
			consume(Supv, Server,Ref,Num-1);
		{'DOWN', Ref, process, _Pid, _Reason} ->
			init(Supv, Num)
	end.
