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
		check_fm(Master, Phone, Data)
	end.


%%初始化阵型
init_fm(Master, Side, Type) ->
	PosList = calc_poslist(Side, Type),
	Master ! {set_fm, self(), PosList},
	PosList.


calc_poslist(Side, Type) ->
	L = hwh.fm_box:type(Type),
	Offset = .random:uniform(3),
	if
		Side =:= "red" -> .lists:map(fun({ID, X, Y}) -> {ID, X+Offset, Y} end, L);
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
		Len >= length(Data#data.poslist) -> Master ! {set_attack, self()};
		true -> loop(Master, Phone, Data)
	end.


check_soldier(Soldier, Side) ->
	case Soldier#soldier.id of
		{_, Side} -> 1;
		_ -> 10 %%what!!!! enemy
	end.
