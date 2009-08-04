-module(hwh.scatter).
-compile(export_all).
-include("schema.hrl").
-include("engine/schema.hrl").


start(Master, Y, Phone) ->
	process_flag(trap_exit, true),
	loop(Master, Y, Phone).


loop(Master, Y, Phone) ->
	{Friend, Enemy} = row_soldier(Y, Phone),
	FriendCnt = length(Friend),
	EnemyCnt = length(Enemy),
	if
		EnemyCnt =:= 0 andalso FriendCnt > 0 -> scatter(Master, Friend, Phone);
		
		EnemyCnt =:= 0 -> none;

		(FriendCnt / EnemyCnt) >= 2 -> scatter(Master, Friend, Phone);

		true -> none
	end,

	receive
		{'EXIT', Master, finish} -> ok;
		_ -> loop(Master, Y, Phone)
	after 1 -> loop(Master, Y, Phone)
	end.


%%检查每一行上的敌我数量
row_soldier(Y, Phone) ->
	{row_soldier(Y, Phone, #grid_info.friend), row_soldier(Y, Phone, #grid_info.enemy)}.
row_soldier(Y, Phone, Key) ->
	Grid = Phone#phone.grid,
	L = .lists:map(
		fun(X) ->
			[GridInfo|_] = .ets:lookup(Grid, {X, Y}),
			element(Key, GridInfo)
		end,
		[0, 1, 2]),
	.lists:umerge(L).


%%下令本行的我军追击敌军
scatter(Master, IDs, Phone) ->
	Soldiers = .lists:flatmap(
		fun(ID) ->
			case hwh.one:soldier(ID) of
				none -> [];
				Soldier -> [Soldier]
			end
		end,
		IDs),
	Info = Phone#phone.info,
	.lists:foreach(
		fun(Soldier) ->
			case .ets:lookup(Info, {pursue, Soldier#soldier.id}) of
				[] -> Master ! {pursue, self(), Soldier#soldier.id};
				_ -> none
			end
		end,
		Soldiers).
