-module(mate).
-export([run/3,soldier/4]).
-include("schema.hrl").

%% 老范军团 之 【士兵突击】
%% 士兵勇敢向前，就近砍人
%% 按职能分为2个进程
%%    1. 指挥官进程 1，负责发出宏观战场指令
%%    2. 中士 1。 负责执行指挥官的命令

run(Channel, Side, _Queue) ->
	
	process_flag(trap_exit,true),
	
	io:format("Ha, Ha, Ha, We come, We fight together	~n",[]),
	
	%%第一个命令为布阵
	commander(beginWar, Side, Channel ).
	
		
%% 指挥官进程
%% 第一拍，创建中士， 然后发布makeLine 布阵
commander(beginWar, Side, Channel) ->

	%% 布阵
	Line = [{1,{0,1}}, {2,{0,3}}, {3,{0,4}}, {4,{0,5}}, {5,{0,6}},
				{6,{1,7}}, {7,{1,8}}, {8,{0,9}}, {9,{0,10}}, {10,{0,12}}],
				
	%% 发出布阵命令
	Army = lists:map(
		fun({SoldierId, {X,Y}}) ->
			if 
				Side == ?RedSide -> Position = {X,Y};
				true -> Position = {14-X, Y}  %镜像对称
			end,
			spawn_link(mate, soldier, [SoldierId, Side, Channel,{make_line, Position}])
		end,
		Line),

	commander(Army,[],{wait_line_ready,0});
	
%% 指挥官下了布阵命令后，就等布阵完成， 布阵完成后才开始战斗
commander(Army, CurrentBF, Command) -> 

	receive
		
		%% 收到子进程的退出信号，不要把自己带掉（channel 发出的是finish 指令）
		{'EXIT', Pid, _M} ->
			commander(lists:delete(Pid, Army), CurrentBF, Command);
		
		%% 收到布阵完成消息
		i_am_ready ->  
			
			case Command of
				
				{wait_line_ready, 9} ->
					lists:foreach(
						fun(SoldierPid) ->
							SoldierPid ! fight
						end,
						Army),
					commander(Army,CurrentBF,fight);
				{wait_line_ready, N} ->
					commander(Army, CurrentBF, {wait_line_ready, N+1});
				
				_Else ->  %% 其他情况忽略
					commander(Army, CurrentBF, Command)
			end;
			
		%% 其他的消息忽略	
		_Else ->
			commander(Army, CurrentBF,Command)
	
	%% 没有消息，就观察战场，等待变化		
	after 1 ->
			
		%% 观察战场，将预估的战场形势发给战士，让战士自己决定如何行动
		NewBf = ft:get_changed_bf(CurrentBF),
		FutureBf = ft:get_future_bf(NewBf),
		lists:foreach(
			fun(SoldierPid) -> 
				SoldierPid! {newround, self(), NewBf, FutureBf}
			end,
			Army),
		commander(Army, NewBf, Command)
	end.

				
%% 战士进程，每拍被唤醒，设法去达成command 目标
soldier(SoldierId, Side, Channel, Command) ->
	
	receive
		
		%% 切换到战斗状态
		fight ->   
			NewCommand = fight;

		%% 新节拍
		{newround, CommanderPid, CurrentBf, FutureBf} ->
			
			%% 看看自己死了没有
			case  getSoldier(CurrentBf, SoldierId, Side) of
				
				false -> 
					NewCommand = finish;
				
				%% 一拍后动作为wait 的战士才需要计算下一步动作
				Soldier  ->  

					case Command of 
						
						{make_line, Destination} ->   %布阵命令
							
							NewCommand = action_makeline(Destination, Soldier, Channel, CommanderPid);
						wait ->
							NewCommand = wait;
						fight -> %战斗命令	
							S2 = getSoldier(FutureBf, SoldierId, Side),
							NewCommand = action_fight(S2, Channel, FutureBf)
					end
				
			end;
			
		%% 其他消息忽略
		_Else ->
			NewCommand = Command
	end,
	
	if
		NewCommand =:= finish -> finish;
		true ->	soldier(SoldierId, Side, Channel, NewCommand)
	end.
	

%% 布阵动作	
action_makeline(Destination, Soldier, Channel, CommanderPid) ->
	
	{SoldierId, _Side} = Soldier#soldier.id,
	case getNextMoveCommand(Soldier, Destination) of
		arrived ->  %到达目标后，进入等待状态
			CommanderPid ! i_am_ready,
			sendMessage(Channel, SoldierId, ?ActionWait),  %%稳定动作
			wait;
		Action ->  %未到达目的地，继续向目的地前进
			sendMessage(Channel, SoldierId, Action),
			{make_line,Destination}
	end.
	

%% 战斗动作	
action_fight(Soldier, Channel, FutureBf) ->
	
	Monitor = 3,
	{SoldierId, _Side} = Soldier#soldier.id,

	if
		SoldierId =:= Monitor -> io:format("Soldier = ~p,  be = ~p ~n",[Soldier,getBestNearbyEnemy(Soldier,FutureBf)]);
		true -> none
	end,
	
	case getBestNearbyEnemy(Soldier,FutureBf) of

		none -> 
			if
				SoldierId =:= Monitor ->	io:format("no enemy nearby ~n",[]);
				true -> none
			end,
			
			action_move(Soldier, Channel, FutureBf);
		
		Enemy ->
			if
				SoldierId =:= Monitor ->io:format("enemy ~p nearby ~n",[Enemy]);
				true -> none
			end,
			
			Action = getAttackAction(Soldier, Enemy),
			
			if
				SoldierId =:= Monitor ->io:format("action = ~p~n", [Action]);
				true -> none
			end,
			
			sendMessage(Channel, SoldierId, Action)
	end,
	fight.

%% 对于可以移动的几个方向进行评估，看看走哪边最划算	
action_move(Soldier, Channel, FutureBf) ->
	
	{SoldierId, _Side} = Soldier#soldier.id,

	case getBestPosition(Soldier, FutureBf) of 
		
		none -> %无处可去，原地等待, 暂时没考虑如何调整面向
			none; 
		
		Position ->
			Action = getMovePlan(Soldier, Position),
			sendMessage(Channel, SoldierId, Action)
	end,
	fight.

%% 找到最理想的敌人
getBestNearbyEnemy(Soldier,FutureBf) ->
	NearByEnemies = getNearByEnemies(Soldier,FutureBf),
	{_Score, Enemy} = getBestEnemy(Soldier, NearByEnemies, FutureBf),
	Enemy.	
getBestEnemy(_S1,[], _FutureBf) ->	{0, none};
getBestEnemy(S1,[S2|Others], FutureBf) ->
	
	case length(getNearByEnemies(S2, FutureBf)) of   %优先攻击可能被围攻的敌人
		1 -> Val1 = 0;
		2 -> Val1 = 0;
		3 -> Val1 = 7;
		4 -> Val1 = 15;
		_Else -> Val1 = 0
	end,
	
	%% 不需要转身就能攻击的对手获得加成
	case ft:ahead(S1,S2) of
		true -> Val2 = 6;
		_E -> Val2 = 0
	end,
	
	%% 血少的对手获得加成
	Val3 = (100 - S2#soldier.hp)/20,
	
	Val = Val1 + Val2 + Val3,
	
	{EVal,E2} = getBestEnemy(S1, Others, FutureBf),
	if
		Val >= EVal -> {Val,S2};
		true -> {EVal, E2}
	end.

%% 选择最合适的一个位置
getBestPosition(Soldier, FutureBf) ->
	
	%% 计算当前状态的得分情况
	{_SId, Side} = Soldier#soldier.id,
	Val = estimate(FutureBf, Side),
	
	Positions = getNearByPositions(Soldier#soldier.position),
	{NewVal, Position} = getBestPosition(Soldier, Positions, FutureBf),

	if
		NewVal =< Val -> none;
		true ->	Position
	end.
	
getBestPosition(_Soldier, [], _FutureBf) -> {-10000,none};
getBestPosition(Soldier, [Position | Others], FutureBf) ->
	
	case ft:position_valid(Position, FutureBf) of
		
		true -> 
			
			{_SId, Side} = Soldier#soldier.id,
			S2 = Soldier#soldier{position = Position},
			FB2 = lists:keyreplace(Soldier#soldier.id,2, FutureBf,S2),
			Val = estimate(FB2, Side),
	
			{Val1,P1} = getBestPosition(Soldier, Others, FutureBf),
			if
				Val > Val1 -> {Val, Position};
				true -> {Val1, P1}
			end;
		
		false -> 
			getBestPosition(Soldier, Others, FutureBf)	
	end.
			
%% 计算每个战士的态势得分
estimate(BattleField, Side)->
	
	ValList = lists:map(
		fun(Soldier) ->
			{_Sid, MySide} = Soldier#soldier.id,
			
			%%如果处于被敌人围攻状态，根据围攻人数扣分
			case length(getNearByEnemies(Soldier,BattleField)) of
				0 -> Val1 = 0;
				1 -> Val1 = 0;
				N -> Val1 = -1000 * (N-1)
			end,
			
			%%评估周边区域内敌我态势
			Val2 = morePeople(Soldier, BattleField) * 3,
			
			{EnemyDistance,Enemy} = getNearestEnemy(Soldier, BattleField),
			if
				%%EnemyDistance =:= 2 -> Val3 = -1500; %% 不送上去让人砍
				Enemy#soldier.hp < Soldier#soldier.hp -> Val3 = (30 - EnemyDistance)*3;
				Enemy#soldier.hp > Soldier#soldier.hp -> Val3 = (30 - EnemyDistance);
				true ->  Val3 = (30 - EnemyDistance)*2
			end,
			
			if
				Side =:= MySide -> Val1 + Val2 + Val3;
				true -> -1 * Val1
			end
		end,
		BattleField),
	
	lists:sum(ValList).

%% 找到最近一个敌人	
getNearestEnemy(Soldier, BattleField) ->
	
	{_Sid, Side} = Soldier#soldier.id,
	
	L1 = lists:map(
		fun(S2) ->
			{_S2id, S2Side} = S2#soldier.id,
			if
				S2Side =:= Side -> {1000,S2};
				true ->
					{getDistance(Soldier#soldier.position, S2#soldier.position),S2}
			end
		end,
		BattleField),
	
	L2 = lists:sort(
		fun({Val1,_S1}, {Val2,_S2}) ->
			Val1 < Val2
		end,
		L1),
	
	lists:nth(1,L2).
				

	
%% 评估范围内，敌我双方比例，占优的得3分，平局不得分，劣势扣3分	
morePeople(Soldier, BattleField) ->
	
	Delta = 2,
	{X1,Y1} = Soldier#soldier.position,
	{_Sid, Side} = Soldier#soldier.id,
	
	%% 过滤出周边区域的双方战士
	Armys = lists:filter(
		fun(S) ->
			{X2,Y2} = S#soldier.position,
			X2 =< X1+Delta andalso X2 >= X1 -Delta andalso Y2 =< Y1 + Delta andalso Y2 >= Y1 -Delta
		end,
		BattleField),
	
	OurArmys = lists:filter(
		fun(S) ->
			{_Sid2, Side2} = S#soldier.id,
			Side =:= Side2
		end,
		Armys),
	
	Val = length(OurArmys) * 2 - length(Armys),
	if
		Val > 0 -> 1;
		Val =:= 0 -> 0;
		true -> -1
	end.

%% 获得周围的四个点
getNearByPositions({X,Y}) ->
	[{X-1,Y},{X+1,Y}, {X,Y-1}, {X,Y+1}].

%% 计算当前战士要移动到目标位置，下一个动作是什么
getMovePlan(Soldier, NearByPosition) ->

	{X1,Y1} = Soldier#soldier.position,
	{X2,Y2} = NearByPosition,
	if
		X1 > X2 -> F = ?DirWest, Action = ?ActionTurnWest;
		X1 < X2 -> F = ?DirEast, Action = ?ActionTurnEast;
		Y1 > Y2 -> F = ?DirSouth, Action = ?ActionTurnSouth;
		Y1 < Y2 -> F = ?DirNorth, Action = ?ActionTurnNorth;
		true -> F = none, Action = ?ActionWait
	end,
	
	if
		Soldier#soldier.facing =:= F -> ?ActionForward;
		true -> Action
	end.

%% 计算如何攻击目标敌人
getAttackAction(Soldier, Enemy) ->
	
	Action = getMovePlan(Soldier, Enemy#soldier.position),

	if
		Action =:= ?ActionForward -> ?ActionAttack;
		true -> Action
	end.
	
	
%% 计算两点间距离
getDistance({X1,Y1},{X2,Y2}) ->
	abs(X1 - X2) + abs(Y1 - Y2).	
	
	
%% 获得贴身的敌人清单
getNearByEnemies(Soldier, Soldiers) ->
	
	{_SoldierId, Side} = Soldier#soldier.id,
	EnemySide = getEnemySide(Side),
	
	lists:filter(
		fun(S) ->
			{_Sid, Es} = S#soldier.id,
			Es =:= EnemySide andalso isNearBy(Soldier,S)
		end,
		Soldiers).

%% 获得下一个移动指令	
getNextMoveCommand(Soldier, Destination) ->
	
	{X1,Y1} = Soldier#soldier.position,
	{X2,Y2} = Destination,
	
	%% 按照先横向接近，再纵向接近的方式计算下一格是什么位置
	if
		X1 > X2 -> X3 = X1 + 1, Y3 = Y1, F = ?DirWest, Action = ?ActionTurnWest;
		X1 < X2 -> X3 = X1 - 1, Y3 = Y1, F = ?DirEast, Action = ?ActionTurnEast;
		Y1 > Y2 -> X3 = X1 , Y3 = Y1 +1, F = ?DirSouth, Action = ?ActionTurnSouth;
		Y1 < Y2 -> X3 = X1 , Y3 = Y1 -1, F = ?DirNorth, Action = ?ActionTurnNorth;
		true -> X3 = X1 , Y3 = Y1, F= "none", Action = ?ActionWait
	end,

	%% 如果位置相同，就结束动作
	%% 如果面向相同， 就向前
	%% 否则先转向
	if
		{X1,Y1} =:= {X3,Y3} -> arrived;
		true ->
			if
				Soldier#soldier.facing =:= F -> ?ActionForward;
				true -> Action
			end
	end.

%% 判断两个角色是否相邻
isNearBy(Soldier1,Soldier2)	->
	P1 = Soldier1#soldier.position,
	P2 = Soldier2#soldier.position,
	getDistance(P1,P2) =< 1.

	
%% 从战场中抽取出战士
getSoldier(Soldiers, SoldierId, Side)->
	tools:keyfind({SoldierId,Side}, 2, Soldiers).	

%% 获得敌方的颜色
getEnemySide(Side) ->
	if
		Side == ?RedSide -> ?BlueSide;
		true -> ?RedSide
	end.	
	
%% 发出战场指令
sendMessage(Channel, SoldierId , {turn,Direction}) ->
	case Direction of 
		west -> sendMessage(Channel, SoldierId, ?ActionTurnWest);
		east -> sendMessage(Channel, SoldierId, ?ActionTurnEast);
		north -> sendMessage(Channel, SoldierId, ?ActionTurnNorth);
		south -> sendMessage(Channel, SoldierId, ?ActionTurnSouth);
		_Other -> none
	end;
sendMessage(Channel, SoldierId, Action) ->
	Channel!{command,Action,SoldierId,0,0}.



















	

