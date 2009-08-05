-module(battlefield).
-author("swingbach@gmail.com").
-export([create/0,get_soldier/2,get_soldier_by_position/1,get_soldier_by_side/1,get_idle_soldier/1]).
-include("schema.hrl").

create() ->
	%%创建战场信息表，用于查找战士信息，及某坐标点信息
	ets:new(battle_field,[named_table,protected,{keypos,#soldier.id}]),
    %%初始化士兵及位置
	init_soldier(?RedSide,0,1,?DirEast),
	init_soldier(?BlueSide,14,1,?DirWest).

init_soldier(Army,X,Y,Direction)->
	Soldiers=?PreDef_army,
	lists:foreach(
		fun(Id) ->
			Soldier=#soldier{
				id={Id,Army},
				position={X,Y+Id},
				hp=100,
				facing = Direction,
				action=?ActionWait,
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
get_soldier_by_position(Position) ->
	Pattern=#soldier{
				id='_',
				position=Position,
				hp='_',
				facing='_',
				action='_',
				act_effect_time = '_',
				act_sequence = '_'
			},
	
	case ets:match_object(battle_field,Pattern) of
		[Soldier | _Other] ->
			Soldier;
		[]->
			none
	end.

%%获得某方所有战士列表
get_soldier_by_side(Side) ->
	Pattern=#soldier{
				id={'_',Side},
				position='_',
				hp='_',
				facing='_',
				action='_',
				act_effect_time = '_',
				act_sequence = '_'
			},
	
	ets:match_object(battle_field,Pattern).

%%获得某方所有处于wait 状态的战士列表
get_idle_soldier(Side) ->
	Pattern=#soldier{
				id={'_',Side},
				position='_',
				hp='_',
				facing='_',
				action=?ActionWait,
				act_effect_time = '_',
				act_sequence = '_'
			},
	
	ets:match_object(battle_field,Pattern).

