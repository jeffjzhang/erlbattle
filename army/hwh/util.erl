-module(hwh.util).
-compile(export_all).
-include("engine/schema.hrl").


enemy(?BlueSide) -> ?RedSide;
enemy(?RedSide) -> ?BlueSide.

facing(?BlueSide) -> ?DirWest;
facing(?RedSide) -> ?DirEast.


calc_area(Side) ->
	case .battlefield:get_soldier_by_side(Side) of
		[] -> none;
		Soldiers -> calc_soldier_area(Soldiers)
	end.


calc_soldier_area([]) -> none;
calc_soldier_area(Soldiers) ->
	S1 = calc_area_bound(Soldiers, fun({X1, _}, {X2, _}) -> X1 > X2 end),
	{East, _} = S1#soldier.position,
	S2 = calc_area_bound(Soldiers, fun({X1, _}, {X2, _}) -> X1 =< X2 end),
	{West, _} = S2#soldier.position,
	S3 = calc_area_bound(Soldiers, fun({_, Y1}, {_, Y2}) -> Y1 > Y2 end),
	{_, North} = S3#soldier.position,
	S4 = calc_area_bound(Soldiers, fun({_, Y1}, {_, Y2}) -> Y1 =< Y2 end),
	{_, South} = S4#soldier.position,
	{length(Soldiers), East, South, West, North}.


calc_area_bound(Soldiers, F) ->
	[H|_] = .lists:sort(
		fun(S1, S2) ->
			F(S1#soldier.position, S2#soldier.position)
		end,
		Soldiers),
	H.


%%寻路
path(#soldier{position = {SX, SY}} = Soldier, {DX, DY}) ->
	path(SX, SY, DX, DY, Soldier#soldier.facing, Soldier#soldier.action, check).
	
%%保证朝向
path(Soldier, Dest, Facing) ->
	Action = turn(Facing),
	case path(Soldier, Dest) of
		stop -> if
				Soldier#soldier.facing =:= Facing -> stop;
				Soldier#soldier.action =:= Action -> stop;
				true -> Action
			end;
		Other -> Other
	end.


%%到达指定位置
path(SX, SY, DX, DY, _, _, _) when SX =:= DX andalso SY =:= DY -> stop;
%%目标在东方
path(SX, SY, DX, DY, Facing, Action, check) when SX < DX ->
	path(SX, SY, DX, DY, Facing, Action, east);
path(SX, _, DX, _, ?DirEast, Action, east) ->
	if
		(SX+1) =:= DX andalso Action =:= ?ActionForward -> none;
		true -> ?ActionForward

	end;
path(_, _, _, _, _, ?ActionTurnEast, east) -> ?ActionForward;
path(_, _, _, _, _, _, east) -> ?ActionTurnEast;
%%目标在西方
path(SX, SY, DX, DY, Facing, Action, check) when SX > DX ->
	path(SX, SY, DX, DY, Facing, Action, west);
path(SX, _, DX, _, ?DirWest, Action, west) ->
	if
		SX =:= (DX+1) andalso Action =:= ?ActionForward -> none;
		true -> ?ActionForward
	end;
path(_, _, _, _, _, ?ActionTurnWest, west) -> ?ActionForward;
path(_, _, _, _, _, _, west) -> ?ActionTurnWest;
%%目标在南方
path(SX, SY, DX, DY, Facing, Action, check) when SY > DY ->
	path(SX, SY, DX, DY, Facing, Action, south);
path(_, SY, _, DY, ?DirSouth, Action, south) ->
	if
		SY =:= (DY+1) andalso Action =:= ?ActionForward -> none;
		true -> ?ActionForward
	end;
path(_, _, _, _, _, ?ActionTurnSouth, south) -> ?ActionForward;
path(_, _, _, _, _, _, south) -> ?ActionTurnSouth;
%%目标在北方
path(SX, SY, DX, DY, Facing, Action, check) when SY < DY ->
	path(SX, SY, DX, DY, Facing, Action, north);
path(_, SY, _, DY, ?DirNorth, Action, north) ->
	if
		(SY+1) =:= DY andalso Action =:= ?ActionForward -> none;
		true -> ?ActionForward
	end;
path(_, _, _, _, _, ?ActionTurnNorth, north) -> ?ActionForward;
path(_, _, _, _, _, _, north) -> ?ActionTurnNorth.


turn(?DirEast) -> ?ActionTurnEast;
turn(?DirWest) -> ?ActionTurnWest;
turn(?DirNorth) -> ?ActionTurnNorth;
turn(?DirSouth) -> ?ActionTurnSouth.


srand() ->
	{A, B, C} = now(),
	.random:seed(A, B, C).


dist({X, Y}, {X2, Y2}) -> abs(X-X2) + abs(Y-Y2);
dist(Soldier, Enemy) ->
	dist(Soldier#soldier.position, Enemy#soldier.position).


road_blocking(Pos) ->
	case .battlefield:get_soldier_by_position(Pos) of
		none -> false;
		_ -> true
	end.


-record(opn,
	{
		pos,
		parent,
		fcos,
		gcos,
		facing
	}
).

%% 深度优先寻路算法
astar(Pos, Pos, _) -> stop;
astar(Src, Dest, Facing) ->
	FirstOpn = #opn
	{
		pos = Src,                %当前位置
		parent = [],              %走到当前位置前面经历的节点
		fcos = 0,                 %走到当前位置的开销（含转身）
		gcos = dist(Src, Dest),   %已知开销+理论开销； 这个值用于评估方案的优劣
		facing = Facing           %当前朝向
	},
	astar_i(Dest, [FirstOpn], []).


astar_i(_, [], _) -> none;
astar_i(Dest, [Opn|_], _) when Dest =:= Opn#opn.pos ->
	[_|Path] = .lists:reverse([Dest|Opn#opn.parent]),
	Path;
astar_i(Dest, [Opn|OpenList], CloseList) ->
	%%1.取出openlist头节点，放入closelist
	CloseList2 = [Opn#opn.pos|CloseList],
	%%2.取周围的节点加入openlist(条件：不在closelist，可以站立)
	AroundOpnList = get_around(Dest, Opn, CloseList2),
	%%3.排序openlist
	OpenList2 = append_opn(Dest, OpenList, AroundOpnList),
	astar_i(Dest, OpenList2, CloseList2).


update_opn(Old, New) when Old#opn.pos =/= New#opn.pos -> Old;
update_opn(Old, New) when New#opn.gcos < Old#opn.gcos -> New;
update_opn(Old, _) -> Old.

append_opn(Dest, OpenList, []) ->
	.lists:sort(fun(O1, O2) ->
			if
				O1#opn.pos =:= Dest -> true; %%dest
				O2#opn.pos =:= Dest -> false; %%dest
				O1#opn.gcos =< O2#opn.gcos -> true;
				true -> false
			end
		end,
		OpenList);
append_opn(Dest, OpenList, [Opn|TOpns]) ->
	OpenList2 = case .lists:keymember(Opn#opn.pos, #opn.pos, OpenList) of
		false -> [Opn|OpenList];
		true ->
			.lists:map(fun(Old) ->
					update_opn(Old, Opn)
				end,
				OpenList)
	end,
	append_opn(Dest, OpenList2, TOpns).


facing_cost(_F, _F) -> 0;
facing_cost(_, _) -> 0.5.
get_around(Dest, Opn, CloseList) ->
	Parent = {SX, SY} = Opn#opn.pos,
	L1 = .lists:map(fun( {F, X, Y} ) ->
			NewPos = {SX + X, SY + Y},
			Dist = dist(NewPos, Dest),
			PreDist = 1 + facing_cost(F, Opn#opn.facing) + Opn#opn.fcos,
			#opn
			{
				pos = NewPos,
				parent = [Parent|Opn#opn.parent],
				fcos = PreDist,
				gcos = PreDist + Dist,
				facing = F
			}
		end,
		[{?DirEast, 1, 0}, {?DirWest, -1, 0}, {?DirNorth, 0, 1}, {?DirSouth, 0, -1}]),
	.lists:filter(fun(O) ->
			{X, Y} = O#opn.pos,
			if
				O#opn.pos =:= Dest -> true; %%dest
				X > 14 orelse X < 0 -> false;
				Y > 14 orelse Y < 0 -> false;
				true -> not (road_blocking(O#opn.pos) orelse .lists:member(O#opn.pos, CloseList))
			end
		end,
		L1).
