% by neoedmund@gmail rev 0.1
% 

-module(neoe).
-include("schema.hrl").
-export([run/3]).

debug(S) ->
	io:format("[neoe]~w~n",[S]).

	
run(Com, Side, Queue) ->
	debug({'燕人张飞在此my side is ', list_to_atom(Side)}),
	%% register(nextNum, spawn( fun() -> nextNum(0) end)),
	lists:foreach(
		fun(Man) ->   
			spawn(fun()-> go(Man, Com) end)
		end,
		? PreDef_army),
	debug('10 man is alive').

	
nextNum(Num) ->
	receive
		{Pidx} ->
			Pidx ! Num,
			nextNum(Num+1)
	end.		
com(Com, C) ->
	debug({'send ', C}),
	Com ! C.
	
go(Man, Com) ->
	% Com ! {command,"attack",Man,0,0},
	% Com ! {command,"forward",Man,2,0},
	X1 = isFacingEnemy(),
	if 
		X1 == true ->		
			com(Com, {command,"attack",Man,0,0});
		true ->
			com(Com, {command,"forward",Man,0,0})
	end,		
	sleep(1000),
	go(Man, Com).
	
	
isFacingEnemy() ->
	true.

sleep(T) ->
	receive
	after T -> true
	end.

