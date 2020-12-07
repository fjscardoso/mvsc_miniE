-module(bb).
-export([start_link/1, init/1]).


start_link(Max) ->
    register(?MODULE, Pid = spawn_link(?MODULE, init, [Max])),
    Pid.

%% The buffer starts empty
init(Max) -> empty(Max).

%% In this state the buffer is neither empty nor full.
%% Listen for either an insert or a remove request, and
%% transition to the next state accordingly.
idle(List, Max) ->
    receive
        {insert, Num, Ref, From} ->
            inserting(List, Max, Num, Ref, From);
        {remove, Ref, From} ->
            removing(List, Max, Ref, From);
        {test, Pid} ->
            Pid ! List,
            idle(List, Max)
    end.

%% Append the element at the end of the list;
%% Decide the next state according to the size of
%% the new list.
inserting(List, Max, Num, Ref, From) ->
    io:format("inserting ~p~n", [Num]),
    From ! {inserted, Num, Ref},
    NewList = List ++ [Num],
    if length(NewList) == Max -> full(NewList, Max)
     ; length(NewList)  < Max -> idle(NewList, Max)
    end.

%% Remove the head of the list - as the elements are appended
%% at the end of the list, removing from the head effectively
%% implements a FIFO policy.
removing([Head | Tail], Max, Ref, From) ->
    io:format("removing ~p~n", [Head]),
    From ! {removed, Head, Ref},
    empty_or_idle(Tail, Max).

%% Decide next state based on what's remaining in the list.
empty_or_idle([], Max)   -> empty(Max);
empty_or_idle(Tail, Max) -> idle(Tail, Max).


%% In this state only remove requests are processed.
%% insert requests will be kept in the mail box for
%% later processing.
full(List, Max) ->
    receive
        {remove, Ref, From} ->
            removing(List, Max, Ref, From)
    end.

%% In this state only insert requests are processed.
%% remove requests will be kept in the mail box for
%% later processing.
empty(Max) ->
    receive
        {insert, Num, Ref, Pid} ->
            inserting([], Max, Num, Ref, Pid)
    end.