-module(bb).

-compile(export_all).

%-export([start/1, insert/1, remove/0]).

%-record(buffer, {[], max}).

%start(Max) ->
%	register(?MODULE, Pid=spawn_link(?MODULE, init, [Max])),
%		Pid.

start_link(Max) ->
    register(?MODULE, Pid=spawn_link(?MODULE, init, [Max])),
    Pid.

init(Max) -> empty(Max).

idle(List, Max) -> 
	receive
		{insert, Num, Ref, From} -> 
				inserting(List, Max, Num, Ref, From);
		{remove, Ref, From} ->
				removing(List, Max, Ref, From);
		{test, Pid} ->
			Pid ! List,
			idle(List,Max)
	end.

inserting(List, Max, Num, Ref, From) ->
	io:format("inserting ~p~n", [Num]),
	From ! {inserted, Num, Ref},
	ExList = [Num|List],
	if 
	    length(ExList) == Max ->
			full(ExList, Max);
	    length(ExList) < Max ->
			idle(ExList, Max)
	end.


removing([H|T], Max, Ref, From) ->
	io:format("removing ~p~n", [H]),
	From ! {removed, H, Ref},
	if T =/= [] ->
		idle(T,Max);
	T =:= [] ->
		empty(Max)
	end.

full(List, Max) ->
	receive 
		{remove, Ref, From} -> 
			removing(List, Max, Ref, From)
	end.

empty(Max) ->
	receive
		{insert, Num, Ref, Pid} ->
			inserting([], Max, Num, Ref, Pid)
	end.

insert(Num) ->
	?MODULE ! {insert, Num, make_ref(), self()}.

remove() ->
	?MODULE ! {remove, make_ref(), self()}.





			


