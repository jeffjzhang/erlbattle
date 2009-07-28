-module(madDog).
-export([run/3,commander/3,sergeant/3]).
-include("schema.hrl").


%% 老范军团 之 【疯狗战阵】
%% 疯狗就是见人咬人，见狗咬狗
%% 按职能分为12个进程
%%    1. 指挥官进程 1，负责发出宏观战场指令
%%    2. 中士 1。 负责执行指挥官的命令

run(Channel, Side, _Queue) ->
	
	io:format("Wang, Wang, Wang, We comes, We bite	~n",[]),
	
	%% 创建通讯官进程，待命
	Sergeant = spawn_link(madDog,sergeant, [Side, Channel, []]),
	
	%% 创建一个用于负责执行指令队列，且协调战士动作的进程, 第一个命令为布阵
	spawn_link(madDog, commander, [makeLine, Side, Sergeant]),
	
	%% 他等到kill 的时候才能死，然后能够把儿子都带下来。否则没法关掉这么多儿子
	tools:sleep(1000000).
	
%% 指挥官进程
%% 第一拍，makeLine 布阵
commander(makeLine, Side, Sergeant) ->

	%% 布阵
	if
		Side == "red" ->
			Line = [{1,{4,0}}, {2,{3,1}}, {3,{3,2}}, {4,{2,3}}, {5,{3,4}},
				{6,{2,5}}, {7,{2,7}}, {8,{2,9}}, {9,{2,11}}, {10,{2,13}}];
		true ->
			Line = [{1,{12,1}}, {2,{12,3}}, {3,{12,5}}, {4,{12,7}}, {5,{12,9}},
				{6,{11,10}}, {7,{12,11}}, {8,{11,12}}, {9,{11,13}}, {10,{10,14}}]
	end,
				
	%% 发出布阵命令
	lists:foreach(
		fun({SoldierId, Position}) ->
			Sergeant ! {SoldierId, {makeLine, Position}}
		end,
		Line),

	commander(goSleep).
	
%% 第二拍：疯狗的指挥官下了布阵命令后，就去睡觉了， 放疯狗自己去咬人去了。	其他算法的指挥官可能会有其他事情
commander(goSleep) -> true.

%% 中士进程
%% 指令格式为 {SoldierId, {orderType, OrderRelatedInfomations...}}
sergeant(Side, Channel, Orders) ->	

	%% 有新的指令的时候，先维护整个指令队列
	receive
		
		Order  -> 
			{SoldierId, _Plan} = Order,
			NewOrders = lists:keystore(SoldierId, 1, Orders, Order),  % 一旦有指令，就一直把指令全部取完，再去做执行
			sergeant(Side, Channel, NewOrders)
	after 10 -> 
		Soldiers = ets:tab2list(battle_field),
		sergeant(Side, Channel, processOrders(Side, Channel, Soldiers, Orders)) % 执行所有动作
	end.
		
%% 执行指令队列
processOrders(_Side, _Channel, _Soldiers, [] ) -> [];
processOrders(Side, Channel, Soldiers, [Order | Other] ) ->
	
	case processOrder(Side, Channel, Soldiers, Order) of

		false -> processOrders(Side, Channel, Soldiers, Other );   %找不到自己（被杀）， 就滤掉这个指令
		none -> processOrders(Side, Channel, Soldiers, Other );    %目标已达成， 就滤掉这个指令
		NewOrder -> [NewOrder] ++ processOrders(Side, Channel, Soldiers, Other )
	end.


%% ProcessOrder 如果该目标达成，输出[], 清掉目标。 否则永远返回原来的，以便下一轮继续去执行
%% 执行makeLine指令
processOrder(Side, Channel, Soldiers, {SoldierId, {makeLine, Destination}}) ->

	case getSoldierFutureStatus(Side, SoldierId, Soldiers) of   % 根据battle_field 表中的动作，预测下一步战士可能处的状态

		false -> false; %如果出现问题，主要是找不到该战士的话，就清掉这个任务
		
		uncertain -> {SoldierId, {makeLine, Destination}} ;  %下一拍结果不确定，等后面能确定再说
		
		Soldier -> 

			case getNextMoveCommand(Soldier, Destination) of 
		
				arrived -> %已经抵达布阵位置，立刻开始战斗
					case getNearestEnemy(Side, SoldierId,Soldiers) of
						none -> none;  %全部敌人都挂了
						EnemyId -> {SoldierId, {kill, getEnemySide(Side), EnemyId}} %否则就进攻这个新的敌人
					end;				
				Command -> 
					sendMessage(Channel, SoldierId, Command),   			%不用管现在队列里什么东西，不断用新的去冲
					{SoldierId, {makeLine, Destination}}		 %继续走
			end
	end;

%% 执行killAsWish 指令,
processOrder(Side, Channel, Soldiers, {SoldierId, {kill, EnemySide, EnemyId}}) ->
	
	case checkEnemy(Side, SoldierId, EnemySide, EnemyId,Soldiers) of

		false -> false;  % 自己不存在, 清掉指令
			
		dead ->	%对方死了
			case getNearestEnemy(Side, SoldierId,Soldiers) of
				none -> none;  %全部敌人都挂了
				NewEnemyId -> {SoldierId, {kill, EnemySide, NewEnemyId}} %否则就进攻这个新的敌人
			end;
		ahead -> 	%在正前方
			sendMessage(Channel, SoldierId, "attack"),
			{SoldierId, {kill, EnemySide, EnemyId}};		
		{near, Direction} ->	%在边上
			sendMessage(Channel, SoldierId, {turn, Direction}),
			{SoldierId, {kill, EnemySide, EnemyId}};
		_Faraway ->	%不在边上
			Action = getNextMoveCommand(Side, SoldierId, EnemySide, EnemyId,Soldiers),
			sendMessage(Channel,SoldierId, Action),
			{SoldierId, {kill, EnemySide, EnemyId}}
	end.


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
		X1 > X2 -> X3 = X1 + 1, Y3 = Y1, F = "west", Action = "turnWest";
		X1 < X2 -> X3 = X1 - 1, Y3 = Y1, F = "east", Action = "turnEast";
		Y1 > Y2 -> X3 = X1 , Y3 = Y1 +1, F = "south", Action = "turnSouth";
		Y1 < Y2 -> X3 = X1 , Y3 = Y1 -1, F = "north", Action = "turnNorth";
		true -> X3 = X1 , Y3 = Y1, F= "none", Action = "wait"
	end,

	%% 如果位置相同，就结束动作
	%% 如果面向相同， 就向前
	%% 否则先转向
	if
		{X1,Y1} == {X3,Y3} -> arrived;
		true ->
			if
				Soldier#soldier.facing == F -> "forward";
				true -> Action
			end
	end.

%% 从战场中抽取出战士
getSoldier(Soldiers, Side, SoldierId)->
	lists:keyfind({SoldierId,Side}, 2, Soldiers).

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
		Side == "red" -> "blue";
		true -> "red"
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

	case lists:keyfind({SoldierId,Side} , 2, Soldiers) of
	
		false -> false;
		
		Soldier ->  
			NewSoldiers = getSoldiersFutureStatus(Soldiers, Soldier#soldier.act_effect_time),
			NewSoldier = lists:keyfind({SoldierId,Side} , 2, NewSoldiers),  %此时不可能找不到
			S2 = lists:keydelete(NewSoldier#soldier.id , 2 , NewSoldiers),
			%% 看看有没有人在同一格的，有就是状态不确定
			%% 这里没有考虑 act_sequece 抢占问题
			case lists:keysearch(NewSoldier#soldier.position, 3 ,S2) of
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

				"forward" -> Soldier#soldier{position = calcDestination(Soldier#soldier.position, Soldier#soldier.facing, 1)};
				"back" -> Soldier#soldier{position = calcDestination(Soldier#soldier.position, Soldier#soldier.facing, -1)};
				"turnWest" -> Soldier#soldier{facing = "west"};
				"turnEast" -> Soldier#soldier{facing = "east"};
				"turnSouth" -> Soldier#soldier{facing = "soutch"};
				"turnNorth" -> Soldier#soldier{facing = "north"};
				_Other -> Soldier  %其他包括attack 和wait  这两个都不会影响战士的位置和朝向
			end
	end.
	
%% 计算移动一步后，目标位置	
calcDestination(Position, Facing, Direction) ->
	
	{Px, Py} = Position,
	
	if  
		Facing == "west" -> {Px - Direction, Py};
		Facing == "east" -> {Px + Direction, Py};
		Facing == "north" -> {Px, Py + Direction};
		Facing == "south" -> {Px, Py - Direction};
		true -> {Px,Py}
	end.
	
%% 发出战场指令
sendMessage(Channel, SoldierId , {turn,Direction}) ->
	case Direction of 
		west -> sendMessage(Channel, SoldierId, "turnWest");
		east -> sendMessage(Channel, SoldierId, "turnEast");
		north -> sendMessage(Channel, SoldierId, "turnNorth");
		south -> sendMessage(Channel, SoldierId, "turnSouth");
		_Other -> none
	end;
sendMessage(Channel, SoldierId, Action) ->
	Channel!{command,Action,SoldierId,0,0}.

















	

