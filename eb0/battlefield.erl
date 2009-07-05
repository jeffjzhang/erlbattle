-module(battlefield).
-author("swingbach@gmail.com").
-export([create/0,get_soldier/2,get_soldier_inbattle/1]).
-include("schema.hrl").

create() ->
	%%创建战场信息表，用于查找战士信息，及某坐标点信息
	ets:new(battle_field,[named_table,protected,{keypos,#soldier.id}]),
    %%初始化士兵及位置
	init_soldier("red",0,2,"E"),
	init_soldier("blue",14,2,"W").

init_soldier(Army,X,Y,Direction)->
	Soldiers=[1,2,3,4,5,6,7,8,9,10],
	lists:foreach(
		fun(Id) ->
			Soldier=#soldier{
				id={Id,Army},
				position={X,Y+Id},
				hp=100,
				facing = Direction,
				%%TODO action以及direction改成整数枚举类型
				action="wait",
				act_effect_time = 0,
				act_sequence =0
			},
			ets:insert(battle_field,Soldier)
		end,
		Soldiers).

%%根据战士编号及战队得到该战士信息
get_soldier(Id,Side) ->
	case ets:lookup(battle_field,{Id,Side}) of
		[Soldier] ->
			Soldier;
		[]->
			none
	end.

%%得到某个坐标点上战士全部信息
get_soldier_inbattle(Position) ->
	Pattern=#soldier{
				id='_',
				position=Position,
				hp='_',
				facing='_',
				action='_'
			},
	case ets:match_object(battle_field,Pattern) of
		[Soldier] ->
			Soldier;
		[]->
			none
	end.




