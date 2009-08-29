-module(h1.util).
-compile(export_all).
-include("schema.hrl").
-include("def.hrl").


forward(?DirEast, Offset) -> {Offset, 0};
forward(?DirWest, Offset) -> {-Offset, 0};
forward(?DirNorth, Offset) -> {0, Offset};
forward(?DirSouth, Offset) -> {0, -Offset}.


-define(Front_Score, 0).
-define(Side_Score, 1).
-define(Back_Score, 2).
near_enemy_score(Soldier, Enemy) ->
	WhichDir = which_dir(Soldier, Enemy),
	ReverseDir = reverse_dir(WhichDir),
	if
		WhichDir =:= Enemy#soldier.facing -> ?Back_Score;
		ReverseDir =:= Enemy#soldier.facing -> ?Front_Score;
		true -> ?Side_Score
	end.


which_dir({MX, MY}, {EX, EY}) ->
	if
		(EY =:= MY) and (EX > MX) -> ?DirEast;
		(EY =:= MY) and (EX < MX) -> ?DirWest;
		(EX =:= MX) and (EY > MY) -> ?DirNorth;
		(EX =:= MX) and (EY < MY) -> ?DirSouth;
		true -> 0
	end;
which_dir(Soldier, Enemy) ->
	which_dir(Soldier#soldier.position, Enemy#soldier.position).


reverse_dir(?DirEast) -> ?DirWest;
reverse_dir(?DirWest) -> ?DirEast;
reverse_dir(?DirNorth) -> ?DirSouth;
reverse_dir(?DirSouth) -> ?DirNorth;
reverse_dir(0) -> 0.


turn_action(?DirEast) -> ?ActionTurnEast;
turn_action(?DirWest) -> ?ActionTurnWest;
turn_action(?DirNorth) -> ?ActionTurnNorth;
turn_action(?DirSouth) -> ?ActionTurnSouth;
turn_action(_) -> ?ActionWait.


dist(Soldier, Enemy) ->
	{EX, EY} = Enemy#soldier.position,
	{MX, MY} = Soldier#soldier.position,
	abs(EX-MX) + abs(EY-MY).


get_enemy(none, _PosList, _Filter, _Sorter) ->
	idead;
get_enemy(Soldier, PosList, Filter, Sorter) ->
	{X, Y} = Soldier#soldier.position,
	L1 = .lists:map(
		fun({OX, OY}) ->
			Pos = {X+OX, Y+OY},
			.battlefield:get_soldier_by_position(Pos)
		end,
		PosList(Soldier)),
	L2 = .lists:filter(
		fun(none) -> false;
		(Enemy) -> Filter(Soldier, Enemy) end,
		L1),
	L3 = .lists:sort(
		fun(E1, E2) -> Sorter(Soldier, E1, E2) end,
		L2),
	F = 
		fun([]) -> none;
		([E|_]) -> {Soldier, E} end,
	F(L3).
get_enemy(ID, Phone, PosList, Filter, Sorter) ->
	Soldier = .battlefield:get_soldier(ID, Phone#phone.side),
	get_enemy(Soldier, PosList, Filter, Sorter).


friend_filter(Phone) ->
	fun(_, #soldier{id = {_, Side}}) -> Side =/= Phone#phone.side end.


notify_detect_result(idead, OldScore, _NewScore) ->
	notify_detect_result_cmn(?X_None_Score, OldScore);
notify_detect_result(none, OldScore, _NewScore) ->
	notify_detect_result_cmn(?X_None_Score, OldScore);
notify_detect_result(_Soldiers, OldScore, NewScore) ->
	notify_detect_result_cmn(NewScore, OldScore).

notify_detect_result_cmn(Score, Score) ->
	Score;
notify_detect_result_cmn(Score, _OldScore) ->
	Master = get(master),
	Master ! {set_score, self(), Score},
	Score.


next_detect_state(idead, _StateName, StateData) -> {stop, normal, StateData};
next_detect_state(_, StateName, StateData) -> {next_state, StateName, StateData, 1}.


