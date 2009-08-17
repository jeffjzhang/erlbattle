-module(hwh.scatter).
-compile(export_all).
-include("hwh_schema.hrl").
-include("schema.hrl").


start(Master, Y, Phone) ->
	process_flag(trap_exit, true),
	loop(Master, Y, Phone).


loop(Master, Y, Phone) ->
	{Friend, Enemy} = row_soldier(Y, Phone),
	FriendCnt = length(Friend),
	EnemyCnt = length(Enemy),
	if
		%% 在带状战区上，敌方没有部队，我方有部队，则下令本行的我军追击敌军
		EnemyCnt =:= 0 andalso FriendCnt > 0 -> scatter(Master, Friend, Phone);
		
		EnemyCnt =:= 0 -> none;

		%% 我方两倍于敌人，则下令本行的我军追击敌军
		(FriendCnt / EnemyCnt) >= 2 -> scatter(Master, Friend, Phone);

		true -> none
	end,

	receive
		{'EXIT', Master, finish} -> ok;
		_ -> loop(Master, Y, Phone)
	after 1 -> loop(Master, Y, Phone)
	end.


%%检查每一行上的敌我数量(这里所谓的行是指3*3战区的一行战区)
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
	%%从战场表中取出所有还活着的战士对象
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
			%% 看看当前战士有没有在追击敌人，如果没有就向主程序发送追击指令
			case .ets:lookup(Info, {pursue, Soldier#soldier.id}) of
				[] -> Master ! {pursue, self(), Soldier#soldier.id};
				_ -> none
			end
		end,
		Soldiers).
