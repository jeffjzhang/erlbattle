-module(soldierGo).
-export([run/3,commander/3,sergeant/4]).
-include("schema.hrl").


%% 老范军团 之 【士兵突击】
%% 士兵勇敢向前，就近砍人
%% 按职能分为2个进程
%%    1. 指挥官进程 1，负责发出宏观战场指令
%%    2. 中士 1。 负责执行指挥官的命令

run(Channel, Side, _Queue) ->
	
	io:format("Ka, Ka, Ka, We come, We conquer	~n",[]),
	
	%% 创建一个用于负责执行指令队列，且协调战士动作的进程, 第一个命令为布阵
	spawn_link(soldierGo, commander, [beginWar, Side, Channel]),
	
	%% 他等到kill 的时候才能死，然后能够把儿子都带下来。否则没法关掉这么多儿子
	tools:sleep(1000000).
	
%% 指挥官进程
%% 第一拍，创建中士， 然后发布makeLine 布阵
commander(beginWar, Side, Channel) ->

	%% 创建通讯官进程，待命
	Sergeant = spawn_link(soldierGo, sergeant, [self(), Side, Channel,[]]),

	%% 布阵
	Line = [{1,{2,0}}, {2,{1,1}}, {3,{2,2}}, {4,{1,3}}, {5,{2,4}},
				{6,{1,5}}, {7,{2,6}}, {8,{2,11}}, {9,{1,12}}, {10,{2,13}}],

	%% 发出布阵命令
	lists:foreach(
		fun({SoldierId, {X,Y}}) ->
			if 
				Side == ?RedSide -> Position = {X,Y};
				true -> Position = {14-X, Y}  %镜像对称
			end,
			Sergeant ! {SoldierId, {makeLine, Position}}
		end,
		Line),

	commander(waitLineReady,Sergeant, 0);
	
%% 第二拍：指挥官下了布阵命令后，就等布阵完成， 布阵完成后才一起向前攻击
commander(waitLineReady, Sergeant, ReadyCount) -> 

	receive
		
		iAmReady ->  
			if 
				ReadyCount =:= 9 -> 
					commander(fightToDeath,Sergeant);
				true ->
					commander(waitLineReady, Sergeant, ReadyCount+1)
			end;
		_Else ->
			commander(waitLineReady, Sergeant, ReadyCount)
	end.

%% 向中士发出战士战斗指令,然后就去睡觉了
commander(fightToDeath,Sergeant) ->
	tools:for(1,10, fun(Soldier) -> Sergeant! {Soldier,{killAsWish}} end),
	io:format("I am go to sleep, good luck, soldiers ! ~n", []),
	tools:sleep(1000000).
				

%% 中士进程
%% 指令格式为 {SoldierId, {orderType, OrderRelatedInfomations...}}
sergeant(Commander, Side, Channel, Orders) ->	

	%% 有新的指令的时候，先维护整个指令队列
	receive
		
		Order  -> 
			{SoldierId, _Plan} = Order,
			NewOrders = lists:keystore(SoldierId, 1, Orders, Order),  % 一旦有指令，就一直把指令全部取完，再去做执行
			sergeant(Commander, Side, Channel, NewOrders)
			
	after 5 -> 
		Soldiers = ets:tab2list(battle_field),
		sergeant(Commander, Side, Channel, processOrders(Commander, Side, Channel, Soldiers, Orders)) % 执行所有动作
	end.
		
%% 执行指令队列
processOrders(_Commander, _Side, _Channel, _Soldiers, [] ) -> [];
processOrders(Commander, Side, Channel, Soldiers, [Order | Other] ) ->
	
	case processOrder(Commander, Side, Channel, Soldiers, Order) of

		false -> processOrders(Commander, Side, Channel, Soldiers, Other );   %找不到自己（被杀）， 就滤掉这个指令
		none -> processOrders(Commander, Side, Channel, Soldiers, Other );    %目标已达成， 就滤掉这个指令
		NewOrder -> [NewOrder] ++ processOrders(Commander, Side, Channel, Soldiers, Other )
	end.


%% ProcessOrder 如果该目标达成，输出[], 清掉目标。 否则永远返回原来的，以便下一轮继续去执行
%% 执行makeLine指令
processOrder(Commander, Side, Channel, Soldiers, {SoldierId, {makeLine, Destination}}) ->

	case getSoldierFutureStatus(Side, SoldierId, Soldiers) of   % 根据battle_field 表中的动作，预测下一步战士可能处的状态

		false -> false; %如果出现问题，主要是找不到该战士的话，就清掉这个任务
		
		uncertain -> {SoldierId, {makeLine, Destination}} ;  %下一拍结果不确定，等后面能确定再说
		
		Soldier -> 
			
			%%if 
			%%	Soldier#soldier.id =:= {1,?RedSide} ->
			%%		io:format("soldier = ~p, Destination = ~p,  Action =~p ~n", [Soldier, Destination, getNextMoveCommand(Soldier, Destination)]);
			%%	true -> none
			%%end,
			
			case getNextMoveCommand(Soldier, Destination) of 
		
				arrived -> %已经抵达布阵位置，报告抵达位置
					Commander! iAmReady,
					none;
				Command -> 
					sendMessage(Channel, SoldierId, Command),   			%不用管现在队列里什么东西，不断用新的去冲
					{SoldierId, {makeLine, Destination}}		 			%继续走
			end
	end;

%% 执行killAsWish 指令,
processOrder(_Commander, Side, _Channel, Soldiers, {SoldierId, {killAsWish}}) ->
	case getNearestEnemy(Side, SoldierId, Soldiers) of
		none -> none;  %全部敌人都挂了
		NewEnemyId -> {SoldierId, {kill, getEnemySide(Side), NewEnemyId}} %否则就进攻这个新的敌人
	end;
	
%% 执行kill 指令,
processOrder(Commander, Side, Channel, Soldiers, {SoldierId, {kill, EnemySide, EnemyId}}) ->
	
	case checkNearbyEnemy(Side, SoldierId, EnemySide, Soldiers) of   %看看边上是否有敌人。 有的话一定要砍，放弃原来的目标
		
		false -> false;  % 自己不存在, 清掉指令
		
		none -> true;
		
		{Nid,_Side} when Nid =/= EnemyId -> 
			processOrder(Commander, Side, Channel, Soldiers, {SoldierId, {kill, EnemySide, Nid}});
		_Else ->
			true
	end,

	case checkEnemy(Side, SoldierId, EnemySide, EnemyId, Soldiers) of

		false -> false;  % 自己不存在, 清掉指令
			
		dead ->	%对方死了
			case getNearestEnemy(Side, SoldierId,Soldiers) of
				none -> none;  %全部敌人都挂了
				NewEnemyId -> {SoldierId, {kill, EnemySide, NewEnemyId}} %否则就进攻这个新的敌人
			end;
		ahead -> 	%在正前方
			sendMessage(Channel, SoldierId, ?ActionAttack),
			{SoldierId, {kill, EnemySide, EnemyId}};		
		{near, Direction} ->	%在边上
			sendMessage(Channel, SoldierId, {turn, Direction}),
			{SoldierId, {kill, EnemySide, EnemyId}};
		_Faraway ->	%不在边上
			Action = getNextMoveCommand(Side, SoldierId, EnemySide, EnemyId,Soldiers),
			sendMessage(Channel,SoldierId, Action),
			{SoldierId, {kill, EnemySide, EnemyId}}
	end.

%% 查看身边有没有可以砍的敌人	
checkNearbyEnemy(Side, SoldierId, EnemySide, Soldiers) ->
	
	case  getSoldier(Soldiers, Side, SoldierId) of
	
		false -> false;
	
		Soldier ->

			%%过滤剩下之后贴身的敌人
			NearbyEnemy = lists:filter(
				fun(S) ->
					{_Sid, Es} = S#soldier.id,
					Es == EnemySide andalso isNearBy(Soldier,S)
				end,
				Soldiers),

			case length(NearbyEnemy) of
			
				0 -> none;
				1 -> 
					(lists:nth(1, NearbyEnemy))#soldier.id;
				_Else -> 
					AheadEnemy = lists:filter(
						fun(S) ->
							S#soldier.position =:= calcDestination(Soldier#soldier.position,Soldier#soldier.facing,1)
						end,
					NearbyEnemy),
					case length(AheadEnemy) of
						0 ->
							(lists:nth(1,NearbyEnemy))#soldier.id;
						_Other ->
							(lists:nth(1,AheadEnemy))#soldier.id
					end
			end
	end.

%% 判断两个角色是否相邻
isNearBy(Soldier1,Soldier2)	->
	P1 = Soldier1#soldier.position,
	P2 = Soldier2#soldier.position,
	getDistance(P1,P2) =< 1.

%% 获得下一个移动指令
getNextMoveCommand(Side, SoldierId, EnemySide, EnemyId, Soldiers) ->
	
	Soldier = getSoldier(Soldiers, Side, SoldierId),
	
	Enemy = getSoldier(Soldiers, EnemySide, EnemyId),
	P2 = Enemy#soldier.position,
	
	%由于调用的时候已经是确定farway , 因此此处直接调，不会造成走到敌人身上去的问题
	getNextMoveCommand(Soldier,P2).  

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

%% 从战场中抽取出战士
getSoldier(Soldiers, Side, SoldierId)->
	tools:keyfind({SoldierId,Side}, 2, Soldiers).	

%% 从战场上找到和自己最近的一个敌人	
getNearestEnemy(Side, SoldierId, Soldiers) ->

	Soldier = getSoldier(Soldiers, Side, SoldierId),

	EnemySide = getEnemySide(Side),

	EnemyArmy = lists:filter(
		fun(S) ->
			{_Sid, Es} = S#soldier.id,
			Es == EnemySide
		end,
		Soldiers),
	case getNearestSoldier(Soldier#soldier.position, EnemyArmy) of
		{none, _Distance } -> none;
		{Enemy, _Distance} ->
			{Eid,_Side} = Enemy#soldier.id,
			Eid
	end.
	

%% 获取和某点最近距离的战士
getNearestSoldier(_Position, []) -> {none, 10000};
getNearestSoldier(Position, [Soldier | Other ]) ->

	D1 = getDistance(Position, Soldier#soldier.position),
	{S2, D2} = getNearestSoldier(Position, Other),
	if
		D1 > D2 -> {S2,D2};
		true -> {Soldier, D1}
	end.

%% 计算两点间距离
getDistance({X1,Y1},{X2,Y2}) ->
	abs(X1 - X2) + abs(Y1 - Y2).
	
%% 获得敌方的颜色
getEnemySide(Side) ->
	if
		Side == ?RedSide -> ?BlueSide;
		true -> ?RedSide
	end.

%% 判断目标地点的相对位置
checkEnemy(Side, SoldierId, EnemySide, EnemyId,Soldiers) ->
	
	Soldier = getSoldier(Soldiers, Side, SoldierId),
	Enemy = getSoldier(Soldiers, EnemySide, EnemyId),
	
	if	
		Soldier == false -> false;
		Enemy == false -> dead;
		true ->
			{X1,Y1} = Soldier#soldier.position,
			{X2,Y2} = Enemy#soldier.position,
			P3 = calcDestination({X1,Y1}, Soldier#soldier.facing, 1),
			
			if
				X1==X2 andalso Y1==Y2 ->false;  %两人重叠， 系统故障，忽略
				{X2,Y2} == P3 -> ahead;         %就在前面,可以砍
				X1==X2 andalso Y1-1 == Y2 ->{near, south};
				X1==X2 andalso Y1+1 == Y2 ->{near, north};
				Y1==Y2 andalso X1+1 == X2 ->{near, east};
				Y1==Y2 andalso X1+1 == X2 ->{near, west};
				true -> faraway
			end	
	end.			

%% 根据所有战场情况，预测下一步该战士可能处的状态；要考虑可能会失败的情况
%% 当状态不确定时，返回uncertain
%% 没找到该人，返回false
getSoldierFutureStatus(Side, SoldierId, Soldiers) -> 

	case tools:keyfind({SoldierId,Side} , 2, Soldiers) of
	
		false -> false;
		
		Soldier ->  
			NewSoldiers = getSoldiersFutureStatus(Soldiers, Soldier#soldier.act_effect_time),
			NewSoldier = tools:keyfind({SoldierId,Side} , 2, NewSoldiers),  %此时不可能找不到
			S2 = lists:keydelete(NewSoldier#soldier.id , 2 , NewSoldiers),
			%% 看看有没有人在同一格的，有就是状态不确定
			%% 这里没有考虑 act_sequece 抢占问题
			case tools:keyfind(NewSoldier#soldier.position, 3 ,S2) of
				false -> NewSoldier;
				_ -> uncertain
			end
	end.

%% 计算一组战士未来的状态
getSoldiersFutureStatus([],_Time)	-> [];
getSoldiersFutureStatus([Soldier | Other],Time)	->
	[getFutureStatus(Soldier,Time)] ++ getSoldiersFutureStatus(Other,Time).

%%计算一个战士的未来状态
getFutureStatus(Soldier,Time) ->	
	
	if
		Soldier#soldier.act_effect_time > Time -> Soldier;  % 如果动作生效时间晚于指定时间，则没有动作
		true ->
			case Soldier#soldier.action of

				?ActionForward -> Soldier#soldier{position = calcDestination(Soldier#soldier.position, Soldier#soldier.facing, 1)};
				?ActionBack -> Soldier#soldier{position = calcDestination(Soldier#soldier.position, Soldier#soldier.facing, -1)};
				?ActionTurnWest -> Soldier#soldier{facing = ?DirWest};
				?ActionTurnEast -> Soldier#soldier{facing = ?DirEast};
				?ActionTurnSouth -> Soldier#soldier{facing = ?DirSouth};
				?ActionTurnNorth -> Soldier#soldier{facing = ?DirNorth};
				_Other -> Soldier  %其他包括attack 和wait  这两个都不会影响战士的位置和朝向
			end
	end.
	
%% 计算移动一步后，目标位置	
calcDestination(Position, Facing, Direction) ->
	
	{Px, Py} = Position,
	
	if  
		Facing == ?DirWest -> {Px - Direction, Py};
		Facing == ?DirEast -> {Px + Direction, Py};
		Facing == ?DirNorth -> {Px, Py + Direction};
		Facing == ?DirSouth -> {Px, Py - Direction};
		true -> {Px,Py}
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

















	

