-module(testWorldClockGetTime).
-export([test/0]).

%% create a faked timer
createFakeTime() ->
	ets:new(battle_timer, [set, protected, named_table]),
	ets:insert(battle_timer, {clock, 23}).
	
%% ²âÊÔgetTime()
test() ->
	createFakeTime(),
	case worldclock:getTime() of 
		23 ->
			true;
		_ ->
			erlang:error("time not correct")
	end,
	ets:delete(battle_timer).
	
