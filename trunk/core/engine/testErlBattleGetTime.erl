-module(testErlBattleGetTime).
-export([test/0]).

%% 测试getTime()
test() ->
	test1(),
	test2(),
	test3().
	
%% 正常情况
test1() ->
	ets:new(battle_timer, [set, protected, named_table]),
	ets:insert(battle_timer, {clock, 23}),
	case erlbattle:getTime() of 
		23 ->
			true;
		_ ->
			erlang:error("time not correct")
	end,
	ets:delete(battle_timer).

%% 空表返回 0	
test2() ->
	ets:new(battle_timer, [set, protected, named_table]),
	case erlbattle:getTime() of 
		0 ->
			true;
		_ ->
			erlang:error("time2 not correct")
	end,
	ets:delete(battle_timer).

%% 没有表的时候返回 -1	
test3() ->
	case erlbattle:getTime() of 
		-1 ->
			true;
		_ ->
			erlang:error("time3 not correct")
	end.
