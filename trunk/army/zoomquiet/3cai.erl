-module(cai3).
-include("schema.hrl").
%%-include("3cai.hrl").
-export([run/3]).

%% @author Zoom.Quiet <Zoom.Quiet@gmail.com>
%% @version 0.0:Hanoi
%% @title ZQ's 3cai army,not realy power now...
%% @doc 3cai plan make built-in team to kill
%% but now,just usage "Towers of Hanoi" role
%% every 3 soldier as one team,follow loop steps
%%  a  b  c    <- team name
%%  2  2  2    <- team No.
%%  ^  ^  ^
%% ^ ^^ ^^ ^
%% a ab bc c   <- team name
%% 1 31 31 3   <- team No.
%% the last one just "skywalk"~flow the field running.
%% @clean


%% @spec run(Channel, Side, Queue) -> none
run(Channel, Side, Queue) ->
	%% 可以不捕获，直接由父进程杀掉
	process_flag(trap_exit, true),
    io:format("TriCai v0.0:Hanoi now!	~n",[]),
    CaiCamp=[1,2,3,4,5,6,7,8,9],
    SkyWalker=10,
    %% main loop
    %% loop(Channel, Side, Queue) -> none
    loop(Channel, Side, Queue) ->

    	%Army = [1,2,3,4,5,6,7,8,9,10],
    	%%lists:foreach(
            %%<fun(Soldier)>>,
    		%%Army),

    	%% 等待结束指令，其实这个程序不需要做任何善后，只是作为例子提供给大家模仿
    	receive
    		%% 结束战斗，可以做一些收尾工作后退出，或者什么都不做
    		%% 这个消息不是必须处理的
    		{'EXIT',_FROM, _Reason} ->  
    			io:format("TriCai v0.0:Hanoi show over ~n",[]);

    		_ ->
    			loop(Channel, Side, Queue)

    	after 100 -> 
    			loop(Channel, Side, Queue)

    	end.

%% 计算某个角色前面是否有人
%% @spec someoneAhead(SoldierId,Side) -> none|false|true.
someoneAhead(SoldierId,Side) ->

	case battlefield:get_soldier(SoldierId,Side) of

		none ->  % 角色不存在（已经挂掉了）
			none;

		Soldier when is_record(Soldier,soldier) ->  % 找到角色

			Position = erlbattle:calcDestination(Soldier#soldier.position, Soldier#soldier.facing, 1),

			case battlefield:get_soldier_by_position(Position) of 
				none ->  		%前面没人
					false;
				_Found ->		%有人
					true
			end;
		_->
			none
	end.







