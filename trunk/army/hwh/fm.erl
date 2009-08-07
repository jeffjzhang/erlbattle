-module(hwh.fm).
-compile(export_all).
-include("schema.hrl").
-include("engine/schema.hrl").

-record(data, {poslist}).

start(Master, Phone, Type) when is_record(Phone, phone) -> 
	process_flag(trap_exit, true),
	hwh.util:srand(),
	PosList = init_fm(Master, Phone#phone.side, Type),
	loop(Master, Phone, #data{poslist=PosList}).


loop(Master, Phone, Data) ->
	receive
		{'EXIT', Master, finish} -> ok;
		_ -> loop(Master, Phone, Data)
	after 1 ->
		check_fm(Master, Phone, Data)  %%检查是否抵达列阵位置
	end.


%%初始化阵型
init_fm(Master, Side, Type) ->
	PosList = calc_poslist(Side, Type),
	Master ! {set_fm, self(), PosList},  %% 向主程序发出列阵的消息
	PosList.

%% 随机决定在 X=1,2,3 的基准线布阵
calc_poslist(Side, Type) ->
	L = hwh.fm_box:type(Type),
	Offset = .random:uniform(3),
	if
		Side =:= ?RedSide -> .lists:map(fun({ID, X, Y}) -> {ID, X+Offset, Y} end, L);
		true -> .lists:map(fun({ID, X, Y}) -> {ID, 14-X-Offset, Y} end, L)
	end.


%%确认战士是否到达指定阵型
check_fm(Master, Phone, Data) ->
	L = .lists:map(
		fun({_, X, Y}) ->
			case hwh.bf:get_soldier_by_position({X, Y}) of
				none -> 0;
				Soldier -> check_soldier(Soldier, Phone#phone.side)
			end
		end,
		Data#data.poslist),
	Len = .lists:sum(L),
	if
		%% 如果部队全部到达指定位置，或者已经触敌，就发起战斗任务
		Len >= length(Data#data.poslist) -> Master ! {set_attack, self()};
		true -> loop(Master, Phone, Data)
	end.

%% 如果是自己人，就是1， 敌人就是10
check_soldier(Soldier, Side) ->
	case Soldier#soldier.id of
		{_, Side} -> 1;
		_ -> 10 %%what!!!! enemy
	end.
