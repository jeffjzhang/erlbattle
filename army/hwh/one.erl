-module(hwh.one).
-compile(export_all).
-include("schema.hrl").
-include("engine/schema.hrl").

-record(data,
	{
		id,
		master,
		
		%%hold, attack
		ai = hold,
		
		%%none, [{X, Y}]
		path = none,
		dest = none,

		soldier = none,
		target = none,

		file
	}
).

start(Master, Phone, ID, AI) when is_record(Phone, phone) ->
	process_flag(trap_exit, true),
	hwh.util:srand(),
	put(phone, Phone),
	%%{Idx, _} = ID,
	%%{ok, File} = .file:open(integer_to_list(Idx), [write]),
	loop(#data{id=ID, master=Master, ai=AI}, Phone).


loop(One, Phone) ->
	case soldier(One#data.id) of
		none -> exit({killed, One});  %%如果自己已经死了，进程自杀
		Soldier ->
			Master = One#data.master,
			NewOne = One#data{soldier = Soldier},
			receive
				{'EXIT', Master, finish} -> ok;

				{set, Master, AI} -> % 根据主程序指令，更换当前计划
					free_play(NewOne#data{ai=AI}, Phone);

				_ -> loop(NewOne, Phone)
			after 1 ->
				free_play(NewOne, Phone)  %没指令的话，就按原定计划战斗
			end
	end.


%%单兵独立决策
%%攻击
free_play(One, Phone) when One#data.ai =:= attack ->
	move_attack(One, Phone);
%%阵型
free_play(One, Phone) ->
	{Dest, NewOne} = next_hold_dest(One, Phone, One#data.path),
	hold_to_dest(NewOne, Phone, Dest).


%%计算布阵的下一个位置
next_hold_dest(One, Phone, none) ->
	case get_fm_dest(One, Phone) of
		none -> {none, One};
		Dest -> search_path(One, Dest)
	end;
next_hold_dest(One, _, []) -> {none, One#data{path = []}};
next_hold_dest(One, _, [Pos|_]) -> {Pos, One}.


%%从阵型中找到合适自己的位置
get_fm_dest(One, Phone) when is_record(Phone, phone) ->
	Info = Phone#phone.info,
	case .ets:lookup(Info, fm_pos) of
		[] -> none;

		[{fm_pos, PosList}|_] -> get_fm_dest(One, PosList)
	end;
%% 如果目标列表中有指名是自己的目标的话，就选择改目标
%% 否则从目标位置列表中挑到一个离自己最近的位置作为自己移动的目标； 
get_fm_dest(One, PosList) ->
	Soldier = One#data.soldier,
	SID = soldier_id(One),
	{X, Y} = Soldier#soldier.position,
	[H|_] = .lists:sort(
		fun({ID1, X1,Y1}, {ID2, X2,Y2}) ->
			if
				ID1 =:= SID andalso ID2 =/= SID -> true;
				ID2 =:= SID andalso ID1 =/= SID -> false;
				
				true ->
					L1 = abs(X1-X) + abs(Y1-Y),
					L2 = abs(X2-X) + abs(Y2-Y),
					L1 =< L2
			end
		end,
		PosList),
	{_, PX, PY} = H,
	{PX, PY}.


acture_facing(?ActionTurnEast, _) -> ?DirEast;
acture_facing(?ActionTurnWest, _) -> ?DirWest;
acture_facing(?ActionTurnNorth, _) -> ?DirNorth;
acture_facing(?ActionTurnSouth, _) -> ?DirSouth;
acture_facing(_, F) -> F.
acture_facing(Soldier) -> acture_facing(Soldier#soldier.action, Soldier#soldier.facing).
acture_pos(Soldier) when Soldier#soldier.action =:= ?ActionForward ->
	.erlbattle:calcDestination(Soldier#soldier.position, Soldier#soldier.facing, 1);
acture_pos(Soldier) -> Soldier#soldier.position.
%%对目标寻路，并更新自己的目标
search_path(One, Dest) ->
	Soldier = One#data.soldier,
	case hwh.util:astar(acture_pos(Soldier), Dest, acture_facing(Soldier)) of
		none -> {none, One};
		stop -> {Dest, One#data{path = []}};
		[] -> {none, One#data{path = []}};
		PosList ->
			%%.io:format(One#data.file, "orig path ~p~n", [PosList]),
			[Pos|_] = PosList,
			{Pos, One#data{path = PosList, dest = Dest}}
	end.


%%移动到目标
hold_to_dest(One, Phone, none) ->
	case soldier(One#data.id) of
		none -> killed;
		Soldier ->
			if
				Soldier#soldier.position =:= One#data.dest -> loop(One, Phone);
				true -> loop(One#data{path = none}, Phone)
			end
	end;
hold_to_dest(One, Phone, Dest) ->
	case soldier(One#data.id) of
		none -> killed;
		Soldier ->
			Channel = Phone#phone.channel,
			Facing = hwh.util:facing(Phone#phone.side),
			NewOne = One#data{soldier = Soldier},
			case hwh.util:path(Soldier, Dest, Facing) of
				stop -> 
					NewPathList = .lists:delete(Dest, NewOne#data.path),
					free_play(NewOne#data{path = NewPathList}, Phone);

				none -> 
					loop(NewOne, Phone);
				
				Cmd -> 
					Channel ! {command, Cmd, soldier_id(One), 0, 0},
					loop(NewOne, Phone)
			end
	end.





%%
soldier(none) -> none;
soldier(Soldier) when is_record(Soldier, soldier) -> soldier(Soldier#soldier.id);
soldier(ID) ->
	{Idx, Side} = ID,
	.battlefield:get_soldier(Idx, Side).


%%移动或者攻击
move_attack(One, Phone) ->
	Soldier = One#data.soldier,
	case touch_forward(Soldier, Phone) of
		none -> purse_enemy(One, Phone);   %如果周边没有任何敌人，就追击敌人
		Other ->
			cmd(One, Phone, Other),
			loop(One, Phone)
	end.


cmd(One, Phone, {NewCmd, Seq}) ->
	Channel = Phone#phone.channel,
	Channel ! {command, NewCmd, soldier_id(One), 0, Seq}.


%%
soldier_id(One) ->
	{ID, _Side} = One#data.id,
	ID.


%%+1 nobody -> forward
%%+2 enemy -> attack later
%%+1 friend -> forward later
%%+1 enemy -> attack
touch_forward(Soldier, Phone) ->
	case front_soldier(Soldier, 1) of
		none ->
			case front_soldier(Soldier, 2) of
				none -> touch_around(Soldier, Phone);
				Other -> touch_forward_soldier(Soldier, Other, 2)
			end;
		Other -> touch_forward_soldier(Soldier, Other, 1)
	end.


%%获取周边目标，决定是否转身
%%使用touch_around 前已经确定了在正面没有直接接触的敌人
%%此时在身边找有没有接触的敌人。 如果有，挑面向自己的一个敌人（应为这个敌人最危险）；如果没有，就随便转向一个敌人
%%如果没有任何敌人就返回none
touch_around(Soldier, _) ->
	L = .lists:flatmap(
		fun(Facing) ->
			Pos = .erlbattle:calcDestination(Soldier#soldier.position, Facing, 1),
			case .battlefield:get_soldier_by_position(Pos) of
				none -> [];
				Other -> turn_to_enemy(Soldier, Other, {Other, Facing})
			end
		end,
		[?DirEast, ?DirWest, ?DirNorth, ?DirSouth]),
	L2 = .lists:sort(
		fun({Other1, Facing1}, {Other2, Facing2}) ->
			if
				Other1#soldier.facing =:= Facing1 -> true;
				Other2#soldier.facing =:= Facing2 -> false;
				true -> true
			end
		end,
		L),
	case L2 of
		[] -> none;
		[{_, F}|_] -> {hwh.util:turn(F), 0}
	end.


%%追击敌人
purse_enemy(One, Phone) ->
	case .ets:lookup(Phone#phone.info, {pursue, One#data.id}) of
		[] -> army_forward(One, Phone); %没有追击指令，就恢复朝对方阵地前景
		_ -> search_enemy(One, Phone)
	end.


%%朝预定方向前进
army_forward(One, Phone) ->
	Soldier = One#data.soldier,
	Facing = hwh.util:facing(Phone#phone.side),
	Action = hwh.util:turn(Facing),
	X = if
		Soldier#soldier.facing =/= Facing andalso Soldier#soldier.action =/= Action -> 
			{Action, 0};
		true -> {?ActionForward, 0}
	end,
	cmd(One, Phone, X),
	loop(One, Phone).


%%查找离自己最近的敌人
search_enemy(One, Phone) ->
	Enemys = .battlefield:get_soldier_by_side(hwh.util:enemy(Phone#phone.side)),
	Soldier = One#data.soldier,
	NewEnemys = .lists:sort(
		fun(E1, E2) ->
			L1 = hwh.util:dist(Soldier, E1),
			L2 = hwh.util:dist(Soldier, E2),
			L1 =< L2
		end,
		Enemys),
	attack_enemy(One, Phone, NewEnemys).


%%冲向敌人
attack_enemy(One, Phone, []) -> army_forward(One, Phone);
attack_enemy(One, Phone, [Enemy|_]) ->
	case soldier(One#data.id) of
		none -> killed;
		Soldier ->
			Target = select_target(Soldier, soldier(One#data.target), Enemy),
			{Dest, NewOne} = search_path(One#data{soldier = Soldier}, Target#soldier.position),
			%%.io:format(One#data.file, " my ~p~n target ~p~n path ~p~n~n", [Soldier, Target, NewOne#data.path]),
			hold_to_dest(NewOne#data{target = Target}, Phone, Dest)
	end.


%%select target from old and new one
select_target(_, none, T2) -> T2;
select_target(_, T1, T2) when T1#soldier.id =:= T2#soldier.id -> T2;
select_target(Soldier, T1, T2) ->
	L1 = hwh.util:dist(Soldier, T1),
	L2 = hwh.util:dist(Soldier, T2),
	if
		(L1 - L2) > 1 -> T2;
		true -> T1
	end.


turn_to_enemy(Soldier, Other, Ret) ->
	{_, S1} = Soldier#soldier.id,
	{_, S2} = Other#soldier.id,
	if
		S1 =/= S2 -> [Ret];
		true -> []
	end.


%%获取战士前方的目标
front_soldier(Soldier, Dist) ->
	Pos = .erlbattle:calcDestination(Soldier#soldier.position, Soldier#soldier.facing, Dist),
	.battlefield:get_soldier_by_position(Pos).


%%根据前方情形决定下一步动作
touch_forward_soldier(Soldier, Other, 1) ->
	{_, Side1} = Soldier#soldier.id,
	{_, Side2} = Other#soldier.id,
	if
		Side1 =:= Side2 -> touch_around(Soldier, get(phone));
		true -> {?ActionAttack, 0}
	end;
touch_forward_soldier(Soldier, Other, 2) ->
	{_, Side1} = Soldier#soldier.id,
	{_, Side2} = Other#soldier.id,
	if
		Side1 =:= Side2 -> touch_around(Soldier, get(phone));
		true -> {?ActionAttack, 4}
	end.
