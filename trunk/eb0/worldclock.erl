-module(worldclock).
-include("schema.hrl").
-export([start/3,getTime/0]).

%% Todo: Sleep 小程序,休息若干毫秒
start(Pid,0,Sleep) ->
	%% 第一次启动，初始化battle_timer表
	ets:new(battle_timer, [set, protected, named_table]),
	ets:insert(battle_timer, {clock, 0}),
	loop(Pid, Sleep).

loop(Pid, Sleep) -> 
	tools:sleep(Sleep),
	
	%% 战场最多运行的次数 
	MaxTurn = 5,

	%% 更新clock值
	Time = ets:update_counter(battle_timer, clock, 1),
	
	if    
		Time == MaxTurn ->
			Pid!{self(), finish},
			ets:delete(battle_timer);
		Time < MaxTurn ->
			Pid !{self(), time, Time},
			loop(Pid, Sleep)
	end.

%% 取时间函数
getTime() ->
	case ets:lookup(battle_timer, clock) of
		[{clock, Time}] ->
			Time;
		_ -> 
			0
	end.
