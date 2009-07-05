-module(testErlBattleTakeAction).
-export([test/0]).
-include("test.hrl").
-include("schema.hrl").

%% 测试getTime()
test() ->
	ets:new(battle_field,[named_table,protected,{keypos,#soldier.id}]),
	
	test1(),
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
	
	
	
