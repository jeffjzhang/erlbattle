-module(erlbattle).
-export([start/0,timer/3]).

%% 战场初始化启动程序
start() ->
    io:format("Server Starting ....~n", []),
	
    %%  TODO: 创建两方部队的初始状态
	io:format("Army matching into the battle fileds....~n", []),
	
	%%  TODO: 这段主要是后面用于让每台机器都能够以相同的结果运行的作用
	%%  io:format("Testing Computer Speed....~n", [])
	Sleep = 10,

	%% 启动一个计时器, 作为战场节拍
	spawn(erlbattle, timer, [self(),1,Sleep]),

	%% 创建两个指令队列， 这两个队列只能由各自看到
	BlueQueue = ets:new(blueQueue, []),
	RedQueue = ets:new(redQueue, []),
	
	%% 启动红方和蓝方的决策程序
	%% TODO:  为了避免某一方通过狂发消息，影响对方， 未来要有独立的通讯程序负责每方的信息
	io:format("Command Please, Generel....~n", []),
	BlueSide = spawn(feardFarmers, start, [self(), "Blue"]),
	RedSide = spawn(englandArmy, start, [self(), "Red"]),
	

	%% 开始战场循环
	run(BlueSide, RedSide,BlueQueue, RedQueue).
		

%% 战场逻辑主程序	
run(BlueSide, RedSide,BlueQueue, RedQueue) ->
	
	receive 
		finish ->
			BlueSide!finish,
			RedSide!finish,
			io:format("Sun goes down, battle finished!~n", []),
			%% 输出战斗结果
			io:format("The winner is blue army ....~n", []);			
		{time, Time} ->
				%% TODO 战场逻辑
				%% do something
				io:format("Time: ~p s ....~n", [Time]),
				%% For Test, 从ETS表中读取并显示战场时钟
				io:format("Battle Clock: ~p ...~n", [ets:lookup(battle_timer, clock)]),
				run(BlueSide, RedSide,BlueQueue, RedQueue);
		{command,Command,Warrior,Time} ->
				%% Todo 接受消息
				io:format("~p warrior want ~p at ~p ~n", [Warrior, Command, Time]),
				
				run(BlueSide, RedSide,BlueQueue, RedQueue)
	end.

%% Todo: Sleep 小程序,休息若干毫秒
timer(Pid, Time,Sleep) -> 
	sleep(Sleep),
	
	%% 战场最多运行的次数 
	MaxTurn = 5,
	%% 第一次启动，初始化battle_timer表
	if 
		Time == 1 ->
			ets:new(battle_timer, [set, protected, named_table]);
		true -> ok
	end,

	%% 更新clock值
	ets:insert(battle_timer, {clock, Time}),

	if    
		Time == MaxTurn ->
			%% 删除battle_timer表
			ets:delete(battle_timer),
			Pid!finish;
		Time < MaxTurn ->
			Pid !{time, Time},
			timer(Pid, Time+1,Sleep)
	end.

	
%% Sleep 工具函数
sleep(Sleep) ->
	receive
	
	after Sleep -> true
    
	end.

