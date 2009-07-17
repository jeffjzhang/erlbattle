-module(testBattleFieldCreate).
-export([test/0]).
-include("test.hrl").
-include("schema.hrl").

%% 测试
test()->
	battlefield:create(),
	test10(),
	test20(),
	ets:delete(battle_field).
	
%%测试根据ID查找战士属性
test10()->
	%%战队错误
	?match(none,battlefield:get_soldier(1,"sdf")),
	%%成功取到信息
	Soldier=#soldier{
				id={2,"red"},
				position={0,1+2},
				hp=100,
				facing="east",
				action="wait",
				act_effect_time=0,
				act_sequence=0
			},
	?match(Soldier,battlefield:get_soldier(2,"red")).

%%测试根据坐标位置查找战士属性
test20()->
	?match(none,battlefield:get_soldier_by_position({1,14})),
	?match(none,battlefield:get_soldier_by_position({14,0})),
	Soldier=#soldier{
			id={8,"blue"},
			position={14,9},
			hp=100,
			facing="west",
			action="wait",
			act_effect_time=0,
			act_sequence=0
			},
	?match(Soldier,battlefield:get_soldier_by_position({14,9})).

