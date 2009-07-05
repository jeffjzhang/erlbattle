-module(erlbattle).
-export([start/0,takeAction/1]).
-include("schema.hrl").
-include("test.hrl").
-include_lib("stdlib/include/ms_transform.hrl").

%% 战场初始化启动程序
start() ->
    io:format("Server Starting ....~n", []),
	
    %% 创建两方部队的初始状态
	io:format("Army matching into the battle fileds....~n", []),
	battlefield:create(),
	
	%%  TODO: 这段主要是后面用于让每台机器都能够以相同的结果运行的作用
	%%  io:format("Testing Computer Speed....~n", [])
	Sleep = 10,

	%% 启动一个计时器, 作为战场节拍
	Timer = spawn(worldclock, start, [self(),0,Sleep]),

	%% 创建两个指令队列， 这两个队列只能由各自看到
	BlueQueue = ets:new(blueQueue, [{keypos, #command.warrior_id}]),
	RedQueue = ets:new(redQueue, [{keypos, #command.warrior_id}]),
	
	%% 启动红方和蓝方的决策程序
	%% TODO:  为了避免某一方通过狂发消息，影响对方， 未来要有独立的通讯程序负责每方的信息
	io:format("Command Please, Generel....~n", []),
	BlueSide = spawn(feardFarmers, start, [self(), "Blue"]),
	RedSide = spawn(englandArmy, start, [self(), "Red"]),
	

	%% 开始战场循环
	run(Timer, BlueSide, RedSide,BlueQueue, RedQueue).
		

%% 战场逻辑主程序
run(Timer, BlueSide, RedSide, BlueQueue, RedQueue) ->
	receive 
		
		{Timer, finish} ->
				BlueSide!finish,
				RedSide!finish,
				io:format("Sun goes down, battle finished!~n", []),
				%% 输出战斗结果
				io:format("The winner is blue army ....~n", []),
				ets:delete(battle_field);		
				
		{Timer, time, Time} ->
				%% TODO 战场逻辑
				%% do something
				io:format("Time: ~p s ....~n", [Time]),
				
				%% 计算所有生效的动作
				takeAction(Time),
				
				%% 从队列拿到处于wait 状态的战士的新的动作，并将该指令从队列中删除
				%% do something
				
				%% 等待下一个节拍
				run(Timer, BlueSide, RedSide,BlueQueue, RedQueue);

		{Side, command,Command,Warrior,Time} ->
				%% 生成一个command 记录
				CmdRec = #command{
						warrior_id = Warrior,
						command_name = Command,
						execute_time = Time},
				case Side of
					%% 蓝方发来的命令
					BlueSide ->
						io:format("BlueSide: warrior ~p want ~p at ~p ~n", [Warrior, Command, Time]),
						ets:insert(BlueQueue, CmdRec),
						?debug_print(true, ets:tab2list(BlueQueue));
					%% 红方发来的命令
					RedSide ->
						io:format("RedSide: ~p warrior want ~p at ~p ~n", [Warrior, Command, Time]),
						ets:insert(RedQueue, CmdRec),
						?debug_print(true, ets:tab2list(RedQueue));
					%% 不知道是那一方发来的命令
					_ ->
						io:format("UnknowSide: ~p warrior want ~p at ~p ~n", [Warrior, Command, Time])
				end,
				run(Timer, BlueSide, RedSide,BlueQueue, RedQueue)
	end.

	
%% 计算当前节拍，所有需要生效的动作
takeAction(Time) ->
	
	%% 首先从战场状态表中取出本节拍生效的动作，取其中一个开始处理
	case getActingWorriar(Time) of
	
		[Worriar] ->
			
			%% 处理Worria 的动作，更新世界表，如果有人被杀，就将该人从世界中移走
			act(Worriar),
			
			%% 再读下一个需要执行的战士			
			takeAction(Time);
		_ ->
			none
	end.
			
	
	
%% 执行一个战士的动作
act(WorriarInfo) ->

    %% forward, 后退 back, 
	%% 转向 turnSouth, turnNorth, turnWest,turnEast
	%% 攻击 attack
	%% 原地待命 wait 
	
	{_, _, _, Action} = WorriarInfo,
	
	if 		
		Action == "forward"  -> actMove(WorriarInfo, 1);
		Action == "back" -> actMove(WorriarInfo, -1);
		Action == "turnSouth" ->actTurn(WorriarInfo,"south");
		Action == "turnWest" ->actTurn(WorriarInfo,"west");
		Action == "turnEast" ->actTurn(WorriarInfo,"east");
		Action == "turnNorth" ->actTurn(WorriarInfo,"north");
		Action == "attack" -> actAttack(WorriarInfo);
		true -> none
	end.
	
	
%% 获得一个当前节拍需要执行任务的战士信息
getActingWorriar(Time) ->

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
actTurn(WorriarInfo,Direction) ->
	{Id, _Position, _Facting, _Action} = WorriarInfo,
	ets:update_element(battle_field, Id, [{6, "wait"},{4, Direction}]).

%% 移动动作，需要看目标格中是否有对手
%% 1 向前走， -1 向后走	
actMove(WorriarInfo, Direction) ->
	
	{Id, Position, Facing, _Action} = WorriarInfo,
	
	DestPosition = calcDestination(Position, Facing, Direction),
	
	%% 如果目标位置是合法的，就移动，否则就放弃该动作,原地不动
	case positionValid(DestPosition) of
		true ->
			ets:update_element(battle_field, Id, [{6, "wait"},{3, DestPosition}]);
		_ ->
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
	%% 2. 目的地有人站着，不能移动
	not ((Px <0 orelse Py < 0 orelse Px >14 orelse Py > 14) orelse
		battlefield:get_soldier_inbattle(Position) /= none).
		
	
%% 攻击对手
actAttack(WorriarInfo) ->
	
	{ID, Position, Facing, _Action} = WorriarInfo,
	{_MyId, MySide} = ID,
	
	DestPosition = calcDestination(Position, Facing, 1),
	
	%% 如果在攻击方向上有敌人的话，计算攻击情况
	case battlefield:get_soldier_inbattle(DestPosition) of
		[Enemy] -> 
			{EID, _EPosition, EHp, _EFacing, _EAction, _EEffTime, _ESeq} = Enemy,	
			{_Eid, ESide} = EID,
			if 
				%% 只能攻击敌人，自己人不能攻击
				MySide /= ESide ->
					case calcHit(WorriarInfo, Enemy) of
						%% 如果hit 返回 0 ，表示该敌人被杀死
						Hit when Hit == 0 ->
							ets:match_delete(battle_field, {EID,'_'});
						%% Hit 大于零，扣减掉对方的血
						Hit when Hit > 0 ->
							ets:update_element(battle_field, EID, [{3, EHp - hit}])
					end
			end;
		_ ->
			true
	end,
	
	%% 将自己的动作结束
	ets:update_element(battle_field, ID, [{5, "wait"}]).
	
	
%% 计算攻击损伤
calcHit(WorriarInfo, Enemy) ->
	
	{_EId, EPosition, EHp, EFacing, _EAction, _EEffTime, _ESeq} = Enemy,	
	{_Id, Position, _Facing, _Action} = WorriarInfo,
	
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
			
	
	
	
