-module(hwh.util).
-compile(export_all).
-include("engine/schema.hrl").


enemy("blue") -> "red";
enemy("red") -> "blue".

facing("blue") -> "west";
facing("red") -> "east".


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
path(SX, _, DX, _, "east", Action, east) ->
	if
		(SX+1) =:= DX andalso Action =:= "forward" -> none;
		true -> "forward"

	end;
path(_, _, _, _, _, "turnEast", east) -> "forward";
path(_, _, _, _, _, _, east) -> "turnEast";
%%目标在西方
path(SX, SY, DX, DY, Facing, Action, check) when SX > DX ->
	path(SX, SY, DX, DY, Facing, Action, west);
path(SX, _, DX, _, "west", Action, west) ->
	if
		SX =:= (DX+1) andalso Action =:= "forward" -> none;
		true -> "forward"
	end;
path(_, _, _, _, _, "turnWest", west) -> "forward";
path(_, _, _, _, _, _, west) -> "turnWest";
%%目标在南方
path(SX, SY, DX, DY, Facing, Action, check) when SY > DY ->
	path(SX, SY, DX, DY, Facing, Action, south);
path(_, SY, _, DY, "south", Action, south) ->
	if
		SY =:= (DY+1) andalso Action =:= "forward" -> none;
		true -> "forward"
	end;
path(_, _, _, _, _, "turnSouth", south) -> "forward";
path(_, _, _, _, _, _, south) -> "turnSouth";
%%目标在北方
path(SX, SY, DX, DY, Facing, Action, check) when SY < DY ->
	path(SX, SY, DX, DY, Facing, Action, north);
path(_, SY, _, DY, "north", Action, north) ->
	if
		(SY+1) =:= DY andalso Action =:= "forward" -> none;
		true -> "forward"
	end;
path(_, _, _, _, _, "turnNorth", north) -> "forward";
path(_, _, _, _, _, _, north) -> "turnNorth".


turn("east") -> "turnEast";
turn("west") -> "turnWest";
turn("north") -> "turnNorth";
turn("south") -> "turnSouth".


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


astar(Pos, Pos, _) -> stop;
astar(Src, Dest, Facing) ->
	FirstOpn = #opn
	{
		pos = Src,
		parent = [],
		fcos = 0,
		gcos = dist(Src, Dest),
		facing = Facing
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
		[{"east", 1, 0}, {"west", -1, 0}, {"north", 0, 1}, {"south", 0, -1}]),
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
