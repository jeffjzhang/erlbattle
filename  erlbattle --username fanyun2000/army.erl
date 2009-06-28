-module(army).
-export([start/3]).

start(BattleFiled, Side, ArmyName) ->
    
	io:format("~p begin to run on ~p army....~n", [ArmyName, Side]).
	