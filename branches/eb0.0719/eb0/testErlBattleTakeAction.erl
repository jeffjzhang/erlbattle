-module(testErlBattleTakeAction).
-export([test/0]).
-include("test.hrl").
-include("schema.hrl").

%% 测试getTime()
test() ->
	ets:new(battle_field,[named_table,protected,{keypos,#soldier.id}]),
	
	%% 这个可以有一个类似null 的空洞来做测试吗？
	Recorder = spawn_link(battleRecorder,start, [self()]),
	register(recorder, Recorder),
	
	test1(), % 向前一步
	test2(), % 向后一步
	test3(), % 有人不能走
	test4(), % 超过边框不能走
	test5(), % 转向测试
	test6(), % 正面攻击测试
	test7(), % 背后攻击测试
	test8(), % 侧面攻击测试
	test9(), % 没打到,攻击测试
	test10(), % 打死一个,攻击测试
	test11(), % 不会误伤自己人
	test12(), % 两人互砍（测试是否能够让多个角色动起来）
	
	%%清理
	exit(whereis(recorder), normal),
	unregister(recorder),
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
	
%% 测试超过边框不能走
test4() ->	
	ets:delete_all_objects(battle_field),
	Soldier=#soldier{
				id={10,"red"},
				position={14,8},
				hp=100,
				facing = "east",
				action="forward",
				act_effect_time = 10,
				act_sequence =0
			},
	ets:insert(battle_field,Soldier),
	erlbattle:takeAction(10),
	Soldier2 = battlefield:get_soldier(10,"red"),
	Soldier3 = Soldier#soldier{action="wait"},
	?match(Soldier2,Soldier3).	
	
%% 测试转向
test5() ->	
	ets:delete_all_objects(battle_field),
	Soldier=#soldier{
				id={10,"red"},
				position={10,10},
				hp=100,
				facing = "east",
				action="turnWest",
				act_effect_time = 10,
				act_sequence =0
			},
	ets:insert(battle_field,Soldier),
	erlbattle:takeAction(10),
	Soldier2 = battlefield:get_soldier(10,"red"),
	Soldier3 = Soldier#soldier{action="wait",facing="west"},
	?match(Soldier2,Soldier3).		
	
%% 正面攻击测试
test6() ->	
	ets:delete_all_objects(battle_field),
	Soldier=#soldier{
				id={10,"red"},
				position={10,10},
				hp=100,
				facing = "north",
				action="attack",
				act_effect_time = 10,
				act_sequence =0
			},
	
	ets:insert(battle_field,Soldier),
	Soldier2 = Soldier#soldier{id={9,"blue"},position={10,11},action="wait",facing = "south"},
	ets:insert(battle_field,Soldier2),
	
	erlbattle:takeAction(10),
	Soldier3 = battlefield:get_soldier(10,"red"),
	Soldier4 = Soldier#soldier{action="wait"},
	?match(Soldier4,Soldier3),

	Soldier5 = battlefield:get_soldier(9,"blue"),
	Soldier6 = Soldier2#soldier{hp=90},
	?match(Soldier6,Soldier5).		

%% 背后攻击测试	
test7() ->
	ets:delete_all_objects(battle_field),
	Soldier=#soldier{
				id={10,"red"},
				position={10,10},
				hp=100,
				facing = "north",
				action="attack",
				act_effect_time = 10,
				act_sequence =0
			},
	
	ets:insert(battle_field,Soldier),
	Soldier2 = Soldier#soldier{id={9,"blue"},position={10,11},action="wait"},
	ets:insert(battle_field,Soldier2),
	
	erlbattle:takeAction(10),
	Soldier3 = battlefield:get_soldier(10,"red"),
	Soldier4 = Soldier#soldier{action="wait"},
	?match(Soldier4,Soldier3),

	Soldier5 = battlefield:get_soldier(9,"blue"),
	Soldier6 = Soldier2#soldier{hp=80},
	?match(Soldier6,Soldier5).	

%% 侧面攻击测试	
test8()->
	ets:delete_all_objects(battle_field),
	Soldier=#soldier{
				id={10,"red"},
				position={10,10},
				hp=100,
				facing = "north",
				action="attack",
				act_effect_time = 10,
				act_sequence =0
			},
	
	ets:insert(battle_field,Soldier),
	Soldier2 = Soldier#soldier{id={9,"blue"},position={10,11},action="wait",facing = "east"},
	ets:insert(battle_field,Soldier2),
	
	erlbattle:takeAction(10),
	Soldier3 = battlefield:get_soldier(10,"red"),
	Soldier4 = Soldier#soldier{action="wait"},
	?match(Soldier4,Soldier3),

	Soldier5 = battlefield:get_soldier(9,"blue"),
	Soldier6 = Soldier2#soldier{hp=85},
	?match(Soldier6,Soldier5).
	
%% 没打到,攻击测试	
test9()->
	ets:delete_all_objects(battle_field),
	Soldier=#soldier{
				id={10,"red"},
				position={10,10},
				hp=100,
				facing = "north",
				action="attack",
				act_effect_time = 10,
				act_sequence =0
			},
	
	ets:insert(battle_field,Soldier),
	Soldier2 = Soldier#soldier{id={9,"blue"},position={10,12},action="wait",facing = "east"},
	ets:insert(battle_field,Soldier2),
	
	erlbattle:takeAction(10),
	Soldier3 = battlefield:get_soldier(10,"red"),
	Soldier4 = Soldier#soldier{action="wait"},
	?match(Soldier4,Soldier3),

	Soldier5 = battlefield:get_soldier(9,"blue"),
	Soldier6 = Soldier2#soldier{hp=100},
	?match(Soldier6,Soldier5).
	
%% 打死一个,攻击测试	
test10()->
	ets:delete_all_objects(battle_field),
	Soldier=#soldier{
				id={10,"red"},
				position={10,10},
				hp=100,
				facing = "north",
				action="attack",
				act_effect_time = 10,
				act_sequence =0
			},
	
	ets:insert(battle_field,Soldier),
	Soldier2 = Soldier#soldier{id={9,"blue"},position={10,11},action="wait",facing = "east",hp=13},
	ets:insert(battle_field,Soldier2),
	
	erlbattle:takeAction(10),
	Soldier3 = battlefield:get_soldier(10,"red"),
	Soldier4 = Soldier#soldier{action="wait"},
	?match(Soldier4,Soldier3),

	case battlefield:get_soldier(9,"blue") of 
		
		Enemy when is_record(Enemy,soldier) ->
			? match(Enemy, "not killed");
		none ->
			true;
		_ ->
			? match("get soldier result" , "unkown")
	end.
	
%% 不会误伤自己人
test11()->
	ets:delete_all_objects(battle_field),
	Soldier=#soldier{
				id={10,"red"},
				position={10,10},
				hp=100,
				facing = "north",
				action="attack",
				act_effect_time = 10,
				act_sequence =0
			},
	
	ets:insert(battle_field,Soldier),
	Soldier2 = Soldier#soldier{id={9,"red"},position={10,11},action="wait",facing = "south"},
	ets:insert(battle_field,Soldier2),
	
	erlbattle:takeAction(10),
	Soldier3 = battlefield:get_soldier(10,"red"),
	Soldier4 = Soldier#soldier{action="wait"},
	?match(Soldier4,Soldier3),

	Soldier5 = battlefield:get_soldier(9,"red"),
	?match(Soldier2,Soldier5).
	
%% 两人互砍（测试是否能够让多个角色动起来）	
test12() ->

	ets:delete_all_objects(battle_field),
	Soldier=#soldier{
				id={10,"red"},
				position={10,10},
				hp=100,
				facing = "north",
				action="attack",
				act_effect_time = 10,
				act_sequence =0
			},
	
	ets:insert(battle_field,Soldier),
	Soldier2 = Soldier#soldier{id={9,"blue"},position={10,11},facing = "south"},
	ets:insert(battle_field,Soldier2),
	
	erlbattle:takeAction(10),
	Soldier3 = battlefield:get_soldier(10,"red"),
	Soldier4 = Soldier#soldier{action="wait",hp=90},
	?match(Soldier4,Soldier3),

	Soldier5 = battlefield:get_soldier(9,"blue"),
	Soldier6 = Soldier2#soldier{action="wait",hp=90},
	?match(Soldier6,Soldier5).	
	
	
	