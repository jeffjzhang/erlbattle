-module(erlbattle).
-export([start/0,takeAction/1,getTime/0]).
-include("schema.hrl").
-include("test.hrl").
-include_lib("stdlib/include/ms_transform.hrl").

%% 战场初始化启动程序
start() ->
    
	io:format("Battle Begin ....~n", []),
	
	%% 如果要更换对手的话，修改这里
	BlueArmy = feardFarmers,
	RedArmy = englandArmy,

	%%  TODO: 这段主要是后面用于让每台机器都能够以相同的结果运行的作用
	Sleep = 1000,
	
	%% 创建一个战场时钟表，并置为零
	ets:new(battle_timer, [set, protected, named_table]),
	ets:insert(battle_timer, {clock, 0}),
	
    %% 创建两方部队的初始状态
	io:format("Army matching into the battle fileds....~n", []),
	battlefield:create(),

	%% 创建通讯队列
	BlueQueue = ets:new(blueQueue, [{keypos, #command.soldier_id}]),	
	RedQueue = ets:new(blueQueue, [{keypos, #command.soldier_id}]),	
	
	%% 启动红方和蓝方的通讯通道
	BlueSide = spawn(channel, start, [self(), "blue",BlueArmy]),
	RedSide = spawn(channel, start, [self(), "red", RedArmy]),
	
	%% 将通讯队列的管理权交给通讯通道
	ets:give_away(BlueQueue, BlueSide, none),
	ets:give_away(RedQueue, RedSide,none),
	
	%% 开始战斗
	loop(BlueSide, RedSide,BlueQueue, RedQueue, Sleep).

%% 战场逻辑主程序
loop(BlueSide, RedSide, BlueQueue, RedQueue, Sleep) ->

	%% 战场最多运行的次数 
	MaxTurn = 5,

	%%获得当前时钟， 战场从 第一秒 开始
	Time = ets:update_counter(battle_timer, clock, 1),

	%% 睡一会，让指挥程序可以考虑
	tools:sleep(Sleep),
	
	%% 计算所有生效的动作
	takeAction(Time),

	%% 检查是否有任意一方已经全部牺牲
	case checkWinner() of

		%% 胜负已分
		{winner, Winner} ->
			io:format("~p army kills all the enemy, they win !! ~n", [Winner]);
	
		%% 胜负未分
		none -> 
			
			%% 判读是否超过了战斗最大轮次
			if	
				Time == MaxTurn ->

					%% 计算胜负
					io:format("Sun goes down, battle finished!~n", []),

					%% 输出战斗结果
					io:format("~p army win the battle!! ~n", [calcWinner()]),
					
					%% 退出清理
					cleanUp(BlueSide,RedSide);
					
				
				%% 开始下一轮的运算					
				true ->

					%% 取红方处于wait 状态的战士的新的动作，执行，并将该指令从队列中删除
					RedIdleSoldiers = battlefield:get_idle_soldier("Red"),
					RedUsedCommand = command(RedIdleSoldiers,RedQueue,Time),
					RedSide ! {expireCommand, RedUsedCommand},
					
					%% 取蓝方处于wait 状态的战士的新的动作，执行，并将该指令从队列中删除					
					BlueIdleSoldiers = battlefield:get_idle_soldier("Blue"),
					BlueUsedCommand = command(BlueIdleSoldiers,BlueQueue,Time),
					BlueSide ! {expireCommand, BlueUsedCommand},

					%% 下一轮战斗
					loop(BlueSide, RedSide, BlueQueue, RedQueue, Sleep)
			end
	end.

%% 对于处于wait 状态的战士，取出下一个指令（如果有的话），并执行之
command([],_Queue,_Time) -> [];
command([Soldier, T], Queue,Time) ->
	
	%% 寻找当前战士新指令, 并执行之
	case getNextCommand(Soldier,Queue) of

		%% 找到指令
		{command, Command} ->
			
			%% 更新战士动作
			NewSoldier = Soldier#soldier{action = Command#command.name, act_effect_time = Time + calcActionTime(Command#command.name)},
			ets:insert(battle_field, NewSoldier),
			
			%% 记录指令序号
			ID = [Command#command.seq_id];
		
		%% 没找到指令
		_ ->
			ID = []
	end,
	ID ++ command(T,Queue,Time).
	

%% 获得一个战士下一步的动作指令	
getNextCommand(Soldier,Queue) ->
    
	%% 提取Soldier 号，Queue由于是分开的，不需要Side 编号
	{SoldierId, _Side} = Soldier#soldier.id,
	Pattern=#command{
		soldier_id = SoldierId,
		name = '_',
		execute_time = '_',
		seq_id = '_'},
	Command = ets:match_object(Queue, Pattern),
	if
		length(Command) == 0 -> none;
		true ->
			[C, _T] = Command,
			C
	end.

%% 定义不同动作生效的时间
calcActionTime(Action) ->

	if
		Action == "forward"  -> 2;
		Action == "back" -> 4;
		Action == "turnSouth" -> 1;
		Action == "turnWest" -> 1;
		Action == "turnEast" -> 1;
		Action == "turnNorth" -> 1;
		Action == "attack" -> 2;
		true -> 0
	end.
	
%% 计算当前节拍，所有需要生效的动作
takeAction(Time) ->
	
	%% 首先从战场状态表中取出本节拍生效的动作，取其中一个开始处理
	case getActingSoldier(Time) of
	
		[Soldier] ->
			
			%% 处理Worria 的动作，更新世界表，如果有人被杀，就将该人从世界中移走
			act(Soldier),
			
			%% 再读下一个需要执行的战士			
			takeAction(Time);
		_ ->
			none
	end.
			
	
	
%% 执行一个战士的动作
act(SoldierInfo) ->

    %% forward, 后退 back, 
	%% 转向 turnSouth, turnNorth, turnWest,turnEast
	%% 攻击 attack
	%% 原地待命 wait 
	
	{_, _, _, Action} = SoldierInfo,
	
	if 		
		Action == "forward"  -> actMove(SoldierInfo, 1);
		Action == "back" -> actMove(SoldierInfo, -1);
		Action == "turnSouth" ->actTurn(SoldierInfo,"south");
		Action == "turnWest" ->actTurn(SoldierInfo,"west");
		Action == "turnEast" ->actTurn(SoldierInfo,"east");
		Action == "turnNorth" ->actTurn(SoldierInfo,"north");
		Action == "attack" -> actAttack(SoldierInfo);
		true -> none
	end.
	
	
%% 获得一个当前节拍需要执行任务的战士信息
getActingSoldier(Time) ->

	%% TODO: 根据sequence 取，以及随机挑选红方，蓝方谁先动
	%% 取出非wait 状态，且动作生效时间 小于等于当前时间的 一个战士
	MS = ets:fun2ms(fun({Soldier, Id, Position,Hp,Facing,Action,Act_effect_time,Act_sequence}) 
			when (Action /= "wait" andalso Act_effect_time =< Time)  ->  
							{Id,Position,Facing,Action} end),
	
	try ets:select(battle_field,MS,1) of
		{ActingSoldier, _Other} ->
			ActingSoldier;
		_->
			none
	catch
		_:_ -> none
	end.

%%转向动作, 不受别人影响
actTurn(SoldierInfo,Direction) ->
	{Id, _Position, _Facting, _Action} = SoldierInfo,
	ets:update_element(battle_field, Id, [{6, "wait"},{5, Direction}]).

%% 移动动作，需要看目标格中是否有对手
%% 1 向前走， -1 向后走	
actMove(SoldierInfo, Direction) ->
	
	{Id, Position, Facing, _Action} = SoldierInfo,
	
	DestPosition = calcDestination(Position, Facing, Direction),
	
	%% 如果目标位置是合法的，就移动，否则就放弃该动作,原地不动
	Valid = positionValid(DestPosition),
		
	if 		
		Valid == true ->  
			ets:update_element(battle_field, Id, [{6, "wait"},{3, DestPosition}]);
		true ->
			ets:update_element(battle_field, Id, [{6, "wait"}])
	end.

%%计算目标移动位置
calcDestination(Position, Facing, Direction) ->
	
	{Px, Py} = Position,
	
	if  
		Facing == "west" -> {Px - Direction, Py};
		Facing == "east" -> {Px + Direction, Py};
		Facing == "north" -> {Px, Py + Direction};
		Facing == "south" -> {Px, Py - Direction};
		true -> {Px,Py}
	end.

%% 判定是否属于合法的目的地
positionValid(Position)	->

	{Px, Py} = Position,

	%% 1. 不允许超框
	%% 2. 目的地不允许有人
	(Px >=0) and (Py>=0) and (Px =<14) and (Py =<14) and  
		(battlefield:get_soldier_by_position(Position) ==none).
	
%% 攻击对手
actAttack(SoldierInfo) ->
	
	{ID, Position, Facing, _Action} = SoldierInfo,
	{_MyId, MySide} = ID,
	
	DestPosition = calcDestination(Position, Facing, 1),

	case battlefield:get_soldier_by_position(DestPosition) of 
		
		Enemy when is_record(Enemy,soldier) -> 

			{_Key, EID, _EPosition, EHp, _EFacing, _EAction, _EEffTime, _ESeq} = Enemy,
			{_Eid, ESide} = EID,

			if 
				%% 只能攻击敌人，自己人不能攻击
				MySide /= ESide ->
					case calcHit(SoldierInfo, Enemy) of
						%% 如果hit 返回 0 ，表示该敌人被杀死
						Hit when Hit == 0 ->
							ets:match_delete(battle_field, Enemy);
						%% Hit 大于零，扣减掉对方的血
						Hit when Hit > 0 ->
							ets:update_element(battle_field, EID, [{4, EHp - Hit}])
					end;
				true -> true
			end;	
		_ -> 
			none
	end,

	
	%% 将自己的动作结束
	ets:update_element(battle_field, ID, [{6, "wait"}]).
	
	
%% 计算攻击损伤
calcHit(SoldierInfo, EnemyInfo) ->
	
	{_Key, _EId, EPosition, EHp, EFacing, _EAction, _EEffTime, _ESeq} = EnemyInfo,	
	{_Id, Position, _Facing, _Action} = SoldierInfo,
	
	%% 计算敌人面对的那格，和背后的那格，其他的都是侧面
	FacePosition = calcDestination(EPosition,EFacing,1),
	BackPosition = calcDestination(EPosition,EFacing,-1),	

	%% 计算出损伤比例
	case Position of 
		FacePosition -> Hit = 10;
		BackPosition -> Hit = 20;
		_ -> Hit = 15
	end,
	
	%% 如果敌人hp 不够，就返回零，表示杀掉了
	%% 否则返回攻击点数
	if
		EHp > Hit -> Hit;
		true -> 0
	end.
			
%% 取时间函数
getTime() ->
	
	try ets:lookup(battle_timer, clock) of
	
		[{clock, Time}] ->
			Time;
		_ -> 0		
	catch
		_:_ -> -1			
	end.
	
%% TODO 实现战场输赢判定
%% 先看剩余人数， 然后看累计血量，如果都一样就判为平局
calcWinner() ->
	
	RedArmy = battlefield:get_soldier_by_side("Red"),
	BlueArmy = battlefield:get_soldier_by_side("Blue"),
	
	RedCount = length(RedArmy),
	BlueCount = length(BlueArmy),
	
	if 
		RedCount == BlueCount ->
			%% 比较血量
			RedBlood = calcBlood(RedArmy),
			BlueBlood = calcBlood(BlueArmy),
			if 
				RedBlood > BlueBlood ->
					{winner, "Red"};
				RedBlood < BlueBlood ->
					{winner, "Blue"};
				true ->
					none
			end;
		RedCount < BlueCount ->
			{winner, "Blue"};
		true ->
			{winner, "Red"}
	end.

%% 检查战斗是否已经结束
checkWinner() ->

	case battlefield:get_soldier_by_side("red") of 
		[] ->
			{winner,"blue"};
		_ ->
			case battlefield:get_soldier_by_side("blue") of
				[] ->
					{winer, "red"};
				_ ->
					none
			end
	end.
		

%% 计算一个队伍的总血量
calcBlood([]) -> 0;
calcBlood([Soldier | T]) ->
	Soldier#soldier.hp + calcBlood(T).
	
%% 退出前，清理环境
cleanUp(BlueSide, RedSide) ->

	io:format("begin to clean the battle field ~n",[]),	
	exit(RedSide, normal),
	exit(BlueSide, normal),
	
	%% 等其他进程都死掉，然后开始清理动作
	tools:sleep(5000),
	ets:delete(battle_field),
	ets:delete(battle_timer).
