-module(randomArmy).
-include("schema.hrl").
-export([run/3]).

-define(Actions, ["attack", "forward", "turnEast", "turnWest", "turnSouth", "turnNorth"]).

run(Channel, Side, Queue) ->
	process_flag(trap_exit, true),
	loop(Channel, Side, Queue).

loop(Channel, Side, Queue) ->
	
        Army = ?PreDef_army,
	lists:foreach(
		fun(Soldier) ->
			%% 问一下指挥官，要这个战士做什么？
			case ask_commander(Soldier) of 
			    none ->
				none;
			    Action ->
				Channel ! {command, Action, Soldier, 0, random:uniform(10)}
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

ask_commander(Soldier) ->
    	%% TODO: 看一下四周有没有敌人
	%% TODO: 如果有敌人，看一下要不要转身，需要转身的先转身，正对面的就砍
	%% TODO: 如果没有敌人，随机一个动作，转身或前进
    "attack".
