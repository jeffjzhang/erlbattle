-module(battlefield).
-author("swingbach@gmail.com").
-export([create/0,get_soldier/2,get_soldier_inbattle/1,test/0]).

-define(error1(Expr, Expected, Actual),
	io:format("~s is ~w instead of ~w at ~w:~w~n",
		  [??Expr, Actual, Expected, ?MODULE, ?LINE])).

-define(match(Expected, Expr),
        fun() ->
		Actual = (catch (Expr)),
		case Actual of
		    Expected ->
			{success, Actual};
		    _ ->
			?error1(Expr, Expected, Actual),
			erlang:error("match failed", Actual)
		end
	end()).

-record(soldier,{
		%%战士编号, tuple形式{编号,所属战队}
		id, 
		%%位置
		position,
		%%血量
		hp,
		%%面朝方向
		direction,
		%%当前动作,
		action,
		%%动作生效时间
		act_effect_time,
		%%行动次序(目前未理解其作用)
	    act_sequenc e	
	}).


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
				direction=Direction,
				%%TODO action以及direction改成整数枚举类型
				action="wait"
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
				direction='_',
				action='_'
			},
	case ets:match_object(battle_field,Pattern) of
		[Soldier] ->
			Soldier;
		[]->
			none
	end.

%%测试根据ID查找战士属性
test10()->
	%%战队错误
	?match(none,get_soldier(1,"sdf")),
	%%成功取到信息
	Soldier=#soldier{
				id={2,"red"},
				position={0,2+2},
				hp=100,
				direction="E",
				action="wait"
			},
	?match(Soldier,get_soldier(2,"red")).

%%测试根据坐标位置查找战士属性
test20()->
	?match(none,get_soldier_inbattle({1,14})),
	?match(none,get_soldier_inbattle({14,0})),
	Soldier=#soldier{
			id={7,"blue"},
			position={14,9},
			hp=100,
			direction="W",
			action="wait"
		},
	?match(Soldier,get_soldier_inbattle({14,9})).

test()->
	create(),
	test10(),
	test20().


