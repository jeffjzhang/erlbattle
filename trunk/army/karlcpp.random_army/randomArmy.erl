-module(randomArmy).
-include("schema.hrl").
-export([run/3]).


run(Channel, Side, Queue) ->
	process_flag(trap_exit, true),
	loop(Channel, Side, Queue).

loop(Channel, Side, Queue) ->
	
        Army = ?PreDef_army,
	lists:foreach(
		fun(SoldierID) ->
			%% 问一下指挥官，要这个战士做什么？
			case ask_commander(SoldierID, Side) of 
			    none ->
				none;
			    Action ->
				Channel ! {command, Action, SoldierID, 0, random:uniform(10)}
			end
		end,
	  
	  Army),

	%% 等待结束指令
	receive
		%% 结束战斗
		{'EXIT',_FROM, _Reason} ->  
			io:format("RandomArmy Stop Attack! ~n",[]);
					
		_ ->
			loop(Channel, Side, Queue)
			
	after 100 -> 
			loop(Channel, Side, Queue)
			
	end.

ask_commander(SoldierID, Side) ->
    %% TODO: 看一下四周有没有敌人
    case battlefield:get_soldier(SoldierID, Side) of 
	%% 战士已死
	none -> none;
	Soldier ->
	    {X, Y} = Soldier#soldier.position,
	    %% 四周位置
	    Around = [{?DirEast, {X+1, Y}},
		      {?DirWest, {X-1, Y}},
		      {?DirSouth, {X, Y+1}},
		      {?DirNorth, {X, Y-1}}],
	    %% 观察四周情况
	    Status = find_around(Around, Side, []),
	    %% 根据周围情况进行决策
	    command_decision(Soldier#soldier.facing, Status)
    end.

%% 观察四周的动静
%% 有四种可能: invalid -- 非法的位置
%%            nobody  -- 无人
%%            comrade -- 战友
%%            enemy   -- 敌人
find_around([H|T], Side, Ret) ->
    {Direction, Position={X, Y}} = H,
    if 
	X >= 0 andalso X =< 14 andalso Y >= 0 andalso Y =< 14 ->
	    find_around(T, Side, [{Direction, anybody_there(Position, Side)}|Ret]);
	true -> find_around(T, Side, [{Direction, invalid}|Ret])
    end;
find_around([], _Side, Ret) -> 
    Ret.


%% 观察一个位置是否人,是什么人
%% 返回结果： nobody   -- 无人
%%           enemy  -- 敌人
%%           comrade   -- 自己人
anybody_there(Position, Side) ->
    case battlefield:get_soldier_by_position(Position) of
	%% 此位置无人
	none -> nobody;
	Soldier ->
	    {_, MySide} = Soldier#soldier.id,
	    
	    if  
		%% 不是我方战士
		MySide =/= Side -> enemy;
		%% 自己人
		true -> comrade
	    end
    end.


%% 根据周围情况进行政策
%% 返回战士的动作指令
command_decision(Facing, Status) ->
    %% 对面有敌人吗? 有则攻击之
    case lists:member({Facing, enemy}, Status) of 
	true -> ?ActionAttack;
	false ->
	    %% 旁边有敌人吗? 有则转身
	    case lists:filter(fun({_D, P}) -> P=:=enemy end, Status) of
		[H|_] -> 
		    {Direction, _} = H,
		    turn_around(Direction);
		%% 附近没有敌人
		[] -> 
		    %% 找一个没人的地儿
		    case lists:filter(fun({_D, P}) -> P=:=nobody end, Status) of
			%% 都有人,我等回再行动吧
			[] -> ?ActionWait;
			Any -> random_action(Facing, Any)
		    end
	    end
    end.

%% 采取随机行动
%% 
random_action(Facing, Status) ->
    Len = length(Status),
    Ran = random:uniform(Len),
    {Direction, _} = lists:nth(Ran, Status),
    if Direction =:= Facing ->
	    ?ActionForward;
       true -> 
	    turn_around(Direction)
    end.



%% 转向哪里
turn_around(?DirEast) -> ?ActionTurnEast;
turn_around(?DirWest) -> ?ActionTurnWest;
turn_around(?DirNorth) -> ?ActionTurnNorth;
turn_around(?DirSouth) -> ?ActionTurnSouth.

