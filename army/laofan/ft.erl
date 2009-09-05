-module(ft).
-export([get_future_bf/1,get_changed_bf/1,position_valid/2,ahead/2]).
-include("schema.hrl").


%% 用于分析战场形式的函数集

%% ###################### get_changed_bf(BF, CurrentBF) ###################### 
%% 战场发生了变化, 输出稳定的结果
%% unchanged  无变化
%% BF  排序过的战场列表（排序为了减少后续比较的难度）
get_changed_bf(CurrentBF) ->
	get_changed_bf(CurrentBF,0).

%% 对于循环进行计数，避免出现对方不动，卡死的情况
get_changed_bf(CurrentBF,100) -> get_stable_bf(CurrentBF);
get_changed_bf(CurrentBF,Count) ->
	
	case get_ordered_bf(ets:tab2list(battle_field)) of
	
		CurrentBF -> 
			tools:sleep(2),
			get_changed_bf(CurrentBF, Count+1);
		NBF ->  
			get_stable_bf(NBF)
	end.
	
%% 循环取战场信息，直到获得稳定版本
%% 这个算法是为了避免主程序在运算过程中，中间状态被错误的取到
get_stable_bf(CurrentBF) ->

	tools:sleep(3),
	case get_ordered_bf(ets:tab2list(battle_field)) of
		
		CurrentBF -> CurrentBF;
		NBF -> get_stable_bf(NBF)
	end.
	
%% 将战场表输出成排序的列表
get_ordered_bf(BF) ->

	lists:sort(
		
		%% 按照蓝色在前，红色在后的方式排序
		fun(F,S)-> 
			{Fid,Fside} = F#soldier.id,
			{Sid,Sside} = S#soldier.id,
			if
				Fside =:= ?RedSide -> FSValue = 100;
				true -> FSValue = 0
			end,
			if
				Sside =:= ?RedSide -> SSValue = 100;
				true -> SSValue = 0
			end,			
			FSValue + Fid < SSValue + Sid			
		end
		,BF).

%% ###################### get_future_bf(BF) ###################### 		

%% 计算当前战局环境下，1拍后的战场状况; 不考虑血量情况		
get_future_bf(Bf)	->
	
	%% 首先要取到稳定的下一拍时间，应为当战场稳定后，很短时间，系统会将时钟改到下一拍，但也要确保不会取错
	CurrentTime = get_stable_timer(),
	io:format("timer = ~p~n", [CurrentTime]),
	
	%% 逐个计算每个战士可能的状态
	lists:map(
		fun(Soldier) ->
			
			NewSoldier = get_future_status(Soldier, CurrentTime),
			case valid_position(NewSoldier , Bf) of
				true -> NewSoldier;
				_Other -> Soldier
			end		
		end,		
		Bf).

%% 当前位置的战士等且等于1时，是正确状态；否则就有可能位置冲突，按照悲观方式估计战士位置
valid_position(Soldier , Bf) ->

	F = lists:filter(
		fun(S) ->
			S#soldier.position =/= Soldier#soldier.position
		end,
		Bf),
	
	length(F) =:= 1.
	
%%计算一个战士的未来状态
get_future_status(Soldier, Time) ->	
	
	if
		Soldier#soldier.act_effect_time > Time -> Soldier;  % 如果动作生效时间晚于指定时间，则没有动作
		true ->
			Action = Soldier#soldier.action,
			Soldier1 = Soldier#soldier{action = ?ActionWait},
			case Action of
				?ActionForward -> Soldier1#soldier{position = calc_destination(Soldier1#soldier.position, Soldier1#soldier.facing, 1)};
				?ActionBack -> Soldier1#soldier{position = calc_destination(Soldier1#soldier.position, Soldier1#soldier.facing, -1)};
				?ActionTurnWest -> Soldier1#soldier{facing = ?DirWest};
				?ActionTurnEast -> Soldier1#soldier{facing = ?DirEast};
				?ActionTurnSouth -> Soldier1#soldier{facing = ?DirSouth};
				?ActionTurnNorth -> Soldier1#soldier{facing = ?DirNorth};
				_Other -> Soldier  %其他包括attack 和wait  这两个都不会影响战士的位置和朝向
			end
	end.
	
%% 计算移动一步后，目标位置	
calc_destination(Position, Facing, Direction) ->
	
	{Px, Py} = Position,
	
	if  
		Facing == ?DirWest -> {Px - Direction, Py};
		Facing == ?DirEast -> {Px + Direction, Py};
		Facing == ?DirNorth -> {Px, Py + Direction};
		Facing == ?DirSouth -> {Px, Py - Direction};
		true -> {Px,Py}
	end.

%% 判断S2是否在S1正前方	
ahead(S1,S2) ->
	P1 = calc_destination(S1#soldier.position, S1#soldier.facing, 1),
	P1 =:= S2#soldier.position.
	
%% 获得稳定状态的战场时钟	
get_stable_timer() ->
	Timer = ets:tab2list(battle_timer),
	[{clock, Time}| _Other] = get_stable_timer(Timer),
	Time .
get_stable_timer(Timer) ->
	
	tools:sleep(2),
	NewTimer = ets:tab2list(battle_timer),
	
	if 
		Timer =:= NewTimer -> Timer;
		true -> get_stable_timer(NewTimer)
	end.
	

%% 判定是否属于合法的目的地
position_valid(Position,Bf)	->

	{Px, Py} = Position,

	%% 1. 不允许超框
	%% 2. 目的地不允许有人
	IsInField = (Px >=0) andalso (Py>=0) andalso (Px =<14) andalso (Py =<14),
	IsNoPersion = not lists:keymember(Position, 3, Bf), 
	IsInField andalso IsNoPersion.










	

