-module(ui).
-export([gettime/0]).

% user interface

gettime() ->
	%io:format("hello~n"),
	timer ! {get, self()},
	receive
		Time -> Time
		after 1000 -> timeout
	end.

getchess(x,y) ->
	% get chess at x, y, return chess
	todo.
getchessById(Id, Army) ->
	% get chess at x, y, return chess
	todo.
getchessAll() ->
	% get all chess living
	todo.

sendCommand(Command) ->
	% send command
	todo.
