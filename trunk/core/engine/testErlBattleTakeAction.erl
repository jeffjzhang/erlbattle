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
				id={10,?RedSide},
				position={10,10},
				hp=100,
				facing = ?DirWest,
				action=?ActionForward,
				act_effect_time = 10,
				act_sequence =0
			},
	ets:insert(battle_field,Soldier),
	erlbattle:takeAction(10),
	Soldier2 = Soldier#soldier{position={9,10},action=?ActionWait},
	Soldier3 = battlefield:get_soldier(10,?RedSide),
	?match(Soldier2,Soldier3).
	
%% 测试向后走一步
test2() ->	
	ets:delete_all_objects(battle_field),
	Soldier=#soldier{
				id={10,?RedSide},
				position={10,10},
				hp=100,
				facing = ?DirNorth,
				action=?ActionBack,
				act_effect_time = 10,
				act_sequence =0
			},
	ets:insert(battle_field,Soldier),
	erlbattle:takeAction(10),
	Soldier2 = Soldier#soldier{position={10,9},action=?ActionWait},
	Soldier3 = battlefield:get_soldier(10,?RedSide),
	?match(Soldier2,Soldier3).	

%% 测试有人挡住的时候不能走
test3() ->	
	ets:delete_all_objects(battle_field),
	Soldier=#soldier{
				id={10,?RedSide},
				position={10,10},
				hp=100,
				facing = ?DirNorth,
				action=?ActionBack,
				act_effect_time = 10,
				act_sequence =0
			},
	ets:insert(battle_field,Soldier),
	Soldier2 = Soldier#soldier{id={9,?BlueSide},position={10,9},action=?ActionWait},
	ets:insert(battle_field,Soldier2),
	
	erlbattle:takeAction(10),
	Soldier3 = battlefield:get_soldier(10,?RedSide),
	Soldier4 = Soldier#soldier{action=?ActionWait},
	?match(Soldier4,Soldier3).	
	
%% 测试超过边框不能走
test4() ->	
	ets:delete_all_objects(battle_field),
	Soldier=#soldier{
				id={10,?RedSide},
				position={14,8},
				hp=100,
				facing = ?DirEast,
				action=?ActionForward,
				act_effect_time = 10,
				act_sequence =0
			},
	ets:insert(battle_field,Soldier),
	erlbattle:takeAction(10),
	Soldier2 = battlefield:get_soldier(10,?RedSide),
	Soldier3 = Soldier#soldier{action=?ActionWait},
	?match(Soldier2,Soldier3).	
	
%% 测试转向
test5() ->	
	ets:delete_all_objects(battle_field),
	Soldier=#soldier{
				id={10,?RedSide},
				position={10,10},
				hp=100,
				facing = ?DirEast,
				action=?ActionTurnWest,
				act_effect_time = 10,
				act_sequence =0
			},
	ets:insert(battle_field,Soldier),
	erlbattle:takeAction(10),
	Soldier2 = battlefield:get_soldier(10,?RedSide),
	Soldier3 = Soldier#soldier{action=?ActionWait,facing=?DirWest},
	?match(Soldier2,Soldier3).		
	
%% 正面攻击测试
test6() ->	
	ets:delete_all_objects(battle_field),
	Soldier=#soldier{
				id={10,?RedSide},
				position={10,10},
				hp=100,
				facing = ?DirNorth,
				action=?ActionAttack,
				act_effect_time = 10,
				act_sequence =0
			},
	
	ets:insert(battle_field,Soldier),
	Soldier2 = Soldier#soldier{id={9,?BlueSide},position={10,11},action=?ActionWait,facing = ?DirSouth},
	ets:insert(battle_field,Soldier2),
	
	erlbattle:takeAction(10),
	Soldier3 = battlefield:get_soldier(10,?RedSide),
	Soldier4 = Soldier#soldier{action=?ActionWait},
	?match(Soldier4,Soldier3),

	Soldier5 = battlefield:get_soldier(9,?BlueSide),
	Soldier6 = Soldier2#soldier{hp=90},
	?match(Soldier6,Soldier5).		

%% 背后攻击测试	
test7() ->
	ets:delete_all_objects(battle_field),
	Soldier=#soldier{
				id={10,?RedSide},
				position={10,10},
				hp=100,
				facing = ?DirNorth,
				action=?ActionAttack,
				act_effect_time = 10,
				act_sequence =0
			},
	
	ets:insert(battle_field,Soldier),
	Soldier2 = Soldier#soldier{id={9,?BlueSide},position={10,11},action=?ActionWait},
	ets:insert(battle_field,Soldier2),
	
	erlbattle:takeAction(10),
	Soldier3 = battlefield:get_soldier(10,?RedSide),
	Soldier4 = Soldier#soldier{action=?ActionWait},
	?match(Soldier4,Soldier3),

	Soldier5 = battlefield:get_soldier(9,?BlueSide),
	Soldier6 = Soldier2#soldier{hp=80},
	?match(Soldier6,Soldier5).	

%% 侧面攻击测试	
test8()->
	ets:delete_all_objects(battle_field),
	Soldier=#soldier{
				id={10,?RedSide},
				position={10,10},
				hp=100,
				facing = ?DirNorth,
				action=?ActionAttack,
				act_effect_time = 10,
				act_sequence =0
			},
	
	ets:insert(battle_field,Soldier),
	Soldier2 = Soldier#soldier{id={9,?BlueSide},position={10,11},action=?ActionWait,facing = ?DirEast},
	ets:insert(battle_field,Soldier2),
	
	erlbattle:takeAction(10),
	Soldier3 = battlefield:get_soldier(10,?RedSide),
	Soldier4 = Soldier#soldier{action=?ActionWait},
	?match(Soldier4,Soldier3),

	Soldier5 = battlefield:get_soldier(9,?BlueSide),
	Soldier6 = Soldier2#soldier{hp=85},
	?match(Soldier6,Soldier5).
	
%% 没打到,攻击测试	
test9()->
	ets:delete_all_objects(battle_field),
	Soldier=#soldier{
				id={10,?RedSide},
				position={10,10},
				hp=100,
				facing = ?DirNorth,
				action=?ActionAttack,
				act_effect_time = 10,
				act_sequence =0
			},
	
	ets:insert(battle_field,Soldier),
	Soldier2 = Soldier#soldier{id={9,?BlueSide},position={10,12},action=?ActionWait,facing = ?DirEast},
	ets:insert(battle_field,Soldier2),
	
	erlbattle:takeAction(10),
	Soldier3 = battlefield:get_soldier(10,?RedSide),
	Soldier4 = Soldier#soldier{action=?ActionWait},
	?match(Soldier4,Soldier3),

	Soldier5 = battlefield:get_soldier(9,?BlueSide),
	Soldier6 = Soldier2#soldier{hp=100},
	?match(Soldier6,Soldier5).
	
%% 打死一个,攻击测试	
test10()->
	ets:delete_all_objects(battle_field),
	Soldier=#soldier{
				id={10,?RedSide},
				position={10,10},
				hp=100,
				facing = ?DirNorth,
				action=?ActionAttack,
				act_effect_time = 10,
				act_sequence =0
			},
	
	ets:insert(battle_field,Soldier),
	Soldier2 = Soldier#soldier{id={9,?BlueSide},position={10,11},action=?ActionWait,facing = ?DirEast,hp=13},
	ets:insert(battle_field,Soldier2),
	
	erlbattle:takeAction(10),
	Soldier3 = battlefield:get_soldier(10,?RedSide),
	Soldier4 = Soldier#soldier{action=?ActionWait},
	?match(Soldier4,Soldier3),

	case battlefield:get_soldier(9,?BlueSide) of 
		
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
				id={10,?RedSide},
				position={10,10},
				hp=100,
				facing = ?DirNorth,
				action=?ActionAttack,
				act_effect_time = 10,
				act_sequence =0
			},
	
	ets:insert(battle_field,Soldier),
	Soldier2 = Soldier#soldier{id={9,?RedSide},position={10,11},action=?ActionWait,facing = ?DirSouth},
	ets:insert(battle_field,Soldier2),
	
	erlbattle:takeAction(10),
	Soldier3 = battlefield:get_soldier(10,?RedSide),
	Soldier4 = Soldier#soldier{action=?ActionWait},
	?match(Soldier4,Soldier3),

	Soldier5 = battlefield:get_soldier(9,?RedSide),
	?match(Soldier2,Soldier5).
	
%% 两人互砍（测试是否能够让多个角色动起来）	
test12() ->

	ets:delete_all_objects(battle_field),
	Soldier=#soldier{
				id={10,?RedSide},
				position={10,10},
				hp=100,
				facing = ?DirNorth,
				action=?ActionAttack,
				act_effect_time = 10,
				act_sequence =0
			},
	
	ets:insert(battle_field,Soldier),
	Soldier2 = Soldier#soldier{id={9,?BlueSide},position={10,11},facing = ?DirSouth},
	ets:insert(battle_field,Soldier2),
	
	erlbattle:takeAction(10),
	Soldier3 = battlefield:get_soldier(10,?RedSide),
	Soldier4 = Soldier#soldier{action=?ActionWait,hp=90},
	?match(Soldier4,Soldier3),

	Soldier5 = battlefield:get_soldier(9,?BlueSide),
	Soldier6 = Soldier2#soldier{action=?ActionWait,hp=90},
	?match(Soldier6,Soldier5).	
	
	
	