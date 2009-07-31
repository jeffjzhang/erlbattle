% by neoedmund@gmail rev 0.1
% 

-module(neoe).
-include("schema.hrl").
-export([run/3]).

debug(S) ->
	io:format("[neoe]~w~n",[S]).

	
run(Com, Side, Queue) ->
	debug({'my side is ', list_to_atom(Side)}),
	%% register(nextNum, spawn( fun() -> nextNum(0) end)),
	lists:foreach(
		fun(Man) ->   
			spawn(fun()-> go(Man, Com) end)
		end,
		[1,2,3,4,5,6,7,8,9,10]),
	debug('10 man is alive').

	
nextNum(Num) ->
	receive
		{Pidx} ->
			Pidx ! Num,
			nextNum(Num+1)
	end.		

go(Man, Com) ->
	% Com ! {command,"attack",Man,0,0},
	Com ! {command,"forward",Man,0,0},
	% debug({'send command ',Man}),
	sleep(1000),
	go(Man, Com).


sleep(T) ->
	receive
	after T -> true
	end.

