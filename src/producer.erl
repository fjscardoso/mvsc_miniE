-module(producer).

-compile(export_all).

start(Server, Num) ->
	spawn_link(?MODULE, init, [Server, Num]).

init(Server, Num) ->
	Ref = erlang:monitor(process, Server),
	produce(Server, Ref, Num).

produce(_,_, 0) -> ok;
produce(Server, Ref, Num) ->
	Server ! {insert, Num, self()}.
