-module(englandArmy).
-export([start/2]).

start(BattleField, Side) ->
    
	io:format("englandArmy begin to run on ~p army....~n", [Side]),
	run(BattleField,Side).
	
run(BattleField, Side) ->
	
	BattleField!{self(), command,"forward",1,0},
	BattleField!{self(), command,"forward",2,0},
	BattleField!{self(), command,"forward",3,0},
	BattleField!{self(), command,"forward",4,0},
	BattleField!{self(), command,"forward",5,0},
	BattleField!{self(), command,"forward",6,0},
	BattleField!{self(), command,"forward",7,0},
	BattleField!{self(), command,"forward",8,0},
	BattleField!{self(), command,"forward",9,0},
	BattleField!{self(), command,"forward",10,0},
	
	receive
		finish ->  % 退出消息，以便让主进程能够结束战斗
			BattleField!{self(), command, Side ++ " Side: finish battle"}
	after 1 -> 
			run(BattleField, Side)
	end.
	