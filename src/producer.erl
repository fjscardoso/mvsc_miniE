-module(producer).

-compile(export_all).

start(Supv, Num) ->
	spawn_link(?MODULE, init, [Supv, Num]).

init(Supv, Num) ->
	AuxRef = make_ref(),
	Supv ! {where, AuxRef, self()},
	receive
		{AuxRef, Server} -> 
			Ref = erlang:monitor(process, Server),
			produce(Supv, Server, Ref, Num)
	end.


produce(_,_,Ref, 0) -> erlang:demonitor(Ref);
produce(Supv, Server, Ref, Num) ->
	Server ! {insert, Num, Ref, self()},
	receive 
		{inserted, Num, Ref} -> 
			produce(Supv, Server,Ref,Num-1);
		{'DOWN', Ref, process, _Pid, _Reason} ->
			init(Supv, Num)
	end.
