-module(testErlBattleTakeAction).
-export([test/0]).
-include("test.hrl").
-include("schema.hrl").

%% 测试getTime()
test() ->
	ets:new(battle_field,[named_table,protected,{keypos,#soldier.id}]),
	
	test1(),
	test2(),
	test3(),
	ets:delete(battle_field).

%% 测试向前走一步
test1() ->	
	ets:delete_all_objects(battle_field),
	Soldier=#soldier{
				id={10,"red"},
				position={10,10},
				hp=100,
				facing = "west",
				action="forward",
				act_effect_time = 10,
				act_sequence =0
			},
	ets:insert(battle_field,Soldier),
	erlbattle:takeAction(10),
	Soldier2 = Soldier#soldier{position={9,10},action="wait"},
	Soldier3 = battlefield:get_soldier(10,"red"),
	?match(Soldier2,Soldier3).
	
%% 测试向后走一步
test2() ->	
	ets:delete_all_objects(battle_field),
	Soldier=#soldier{
				id={10,"red"},
				position={10,10},
				hp=100,
				facing = "north",
				action="back",
				act_effect_time = 10,
				act_sequence =0
			},
	ets:insert(battle_field,Soldier),
	erlbattle:takeAction(10),
	Soldier2 = Soldier#soldier{position={10,9},action="wait"},
	Soldier3 = battlefield:get_soldier(10,"red"),
	?match(Soldier2,Soldier3).	

%% 测试有人挡住的时候不能走
test3() ->	
	ets:delete_all_objects(battle_field),
	Soldier=#soldier{
				id={10,"red"},
				position={10,10},
				hp=100,
				facing = "north",
				action="back",
				act_effect_time = 10,
				act_sequence =0
			},
	ets:insert(battle_field,Soldier),
	Soldier2 = Soldier#soldier{id={9,"blue"},position={10,9},action="wait"},
	ets:insert(battle_field,Soldier2),
	
	erlbattle:takeAction(10),
	Soldier3 = battlefield:get_soldier(10,"red"),
	Soldier4 = Soldier#soldier{action="wait"},
	?match(Soldier4,Soldier3).	