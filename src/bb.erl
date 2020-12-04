-module(bb).

-compile(export_all).

%-export([start/1, insert/1, remove/0]).

%-record(buffer, {[], max}).

start(Max) ->
	register(?MODULE, Pid=spawn_link(?MODULE, init, [Max])),
		Pid.

init(Max) -> empty(Max).

idle(List, Max) -> 
	receive
		{insert, Num, From} -> 
			if length(List) < Max ->
				inserting(List, Max, Num, From);
			length(List) >= Max ->
				full(List, Max)
			end;
		{remove, From} ->
			if List =/= [] ->
				removing(List,Max, From);
			List =:= [] ->
				empty(Max)
			end;
		{test, Pid} ->
			Pid ! List,
			idle(List,Max)
	end.

inserting(List, Max, Num, From) ->
	io:format("inserting ~p~n", [Num]),
	From ! {inserted, Num},
	ExList = [Num|List],
	if 
	    length(ExList) == Max ->
			full(ExList, Max);
	    length(ExList) < Max ->
			idle(ExList, Max)
	end.


removing([H|T], Max, From) ->
	io:format("removing ~p~n", [H]),
	From ! {removed, H},
	if List =/= [] ->
		removing(List,Max, From);
	List =:= [] ->
		empty(Max)
	end;
	idle(T, Max).

full(List, Max) ->
	receive 
		{remove, From} -> 
			removing(List, Max, From)
	end.

empty(Max) ->
	receive
		{insert, Num, Pid} ->
			inserting([], Max, Num, Pid)
	end.

insert(Num) ->
	?MODULE ! {insert, Num, self()}.
	%receive
	%	Msg -> Msg
	%end.

remove() ->
	?MODULE ! {remove, self()}.






			


