-module(lxw).
-include("schema.hrl").
-export([run/3]).

run(Channel, Side, Queue) ->
    
	%% 可以不捕获，直接由父进程杀掉
	process_flag(trap_exit, true),
	
	loop(Channel, Side, Queue,0).

loop(Channel, Side, Queue,N) ->
	
	Army = [1,2,3,4,5,6,7,8,9,10],
	
	lists:foreach(
		fun(Soldier) ->   % 一直朝前， 直到碰到人，然后开始砍	
			case someone_ahead(Soldier,Side) of
				true ->
					Channel!{command,?ActionAttack,Soldier,0,random:uniform(5)};
				false -> 
                                     
                                        case someone_left(Soldier,Side) of
                                             true ->
                                                  io:format("left Side=~p Soldier=~p.......
                                                     ...........................~n",[Side,Soldier]),
                                                  Channel!{command,?ActionTurnNorth,Soldier,0,random:uniform(5)};
                                             false -> 
                                                   case someone_right(Soldier,Side) of
                                                            true ->
                                                                  io:format("right Side=~p Soldier=~p.......
                                                                     ............................~n",[Side,Soldier]),
                                                                  Channel!{command,?ActionTurnSouth,Soldier,0,random:uniform(5)};
                                                            false -> none
                                                    end%%none
                                        end,
                                        case N==0 of 
                                             true ->
                                                Channel!{command,?ActionForward,Soldier,0,random:uniform(3)};
                                             false ->none
                                        end;
				%%	
				_ ->
					none
			end
		end,
		Army),
	tools:sleep(50),
	%% 等待结束指令，其实这个程序不需要做任何善后，只是作为例子提供给大家模仿
	receive
		%% 结束战斗，可以做一些收尾工作后退出，或者什么都不做
		%% 这个消息不是必须处理的
		{'EXIT',_FROM, _Reason} ->  
			io:format("lxw Army Go Back To Castle ~n",[]);
					
		_ ->
			loop(Channel, Side, Queue,N)
			
	after 100 ->    M=N+1,
			loop(Channel, Side, Queue,M)
			
	end.


%% 计算某个角色前面是否有人
someoneAhead(SoldierId,Side) ->
	
	case battlefield:get_soldier(SoldierId,Side) of
		
		none ->  % 角色不存在（已经挂掉了）
			none;
		
		Soldier when is_record(Soldier,soldier) ->  % 找到角色

			Position = erlbattle:calcDestination(Soldier#soldier.position, Soldier#soldier.facing, 1),

			case battlefield:get_soldier_by_position(Position)  of 
				none ->  		%前面没人
					false;
				_Found ->		%有人
					true
			end;
		_->
			none
	end.



%% 计算某个角色左边是否有人
someone_left(SoldierId,Side) ->
	case battlefield:get_soldier(SoldierId,Side) of
		
		none ->  % 角色不存在（已经挂掉了）
			none;
		
		Soldier when is_record(Soldier,soldier) ->  % 找到角色
                        
			Position = left(Soldier#soldier.position, Soldier#soldier.facing, 1),

			case battlefield:get_soldier_by_position(Position)  of 
				none ->  		%前面没人
					false;
				FoundSoldier ->  %有人
                                        {_, FoundSide} = FoundSoldier#soldier.id ,
                                        case Side =:= FoundSide of %%判断是否是自己人
                                             true->
                                                   false;
					     %%Side ==  red ->true;
				             false -> true
					end
			end;
		_->
			none
	end.				
			
			
%%获取左边位置
left(Position, Facing, Direction) ->
	
	{Px, Py} = Position,
	
	if  
		Facing == ?DirWest -> {Px, Py + Direction};
		Facing == ?DirEast -> {Px, Py - Direction};
		Facing == ?DirNorth -> {Px - Direction, Py};
		Facing == ?DirSouth -> {Px + Direction, Py };
		true -> {Px,Py}
	end.


%%获取左边位置
right(Position, Facing, Direction) ->
	
	{Px, Py} = Position,
	
	if  
		Facing == ?DirWest -> {Px, Py - Direction};
		Facing == ?DirEast -> {Px, Py + Direction};
		Facing == ?DirNorth -> {Px + Direction, Py};
		Facing == ?DirSouth -> {Px - Direction, Py };
		true -> {Px,Py}
	end.




%% 计算某个角色左边是否有人
someone_right(SoldierId,Side) ->
	case battlefield:get_soldier(SoldierId,Side) of
		
		none ->  % 角色不存在（已经挂掉了）
			none;
		
		Soldier when is_record(Soldier,soldier) ->  % 找到角色
                        
			Position = right(Soldier#soldier.position, Soldier#soldier.facing, 1),

			case battlefield:get_soldier_by_position(Position)  of 
				none ->  		%前面没人
					false;
				FoundSoldier ->  %有人
                                        {_, FoundSide} = FoundSoldier#soldier.id ,
                                        case Side =:= FoundSide of %%判断是否是自己人
                                             true->
                                                   false;
					     %%Side ==  red ->true;
				             false -> true
					end
			end;
		_->
			none
	end.				

%% 计算某个角色前面是否有人
someone_ahead(SoldierId,Side) ->
	
	case battlefield:get_soldier(SoldierId,Side) of
		
		none ->  % 角色不存在（已经挂掉了）
			none;
		
		Soldier when is_record(Soldier,soldier) ->  % 找到角色

			Position = ahead(Soldier#soldier.position, Soldier#soldier.facing, 1),

			case battlefield:get_soldier_by_position(Position)  of 
				none ->  		%前面没人
					false;
				_Found ->		%有人
					true
			end;
		_->
			none
	end.	


%%获取左边位置
ahead(Position, Facing, Direction) ->
	
	{Px, Py} = Position,
	
	if  
		Facing == ?DirWest -> {Px - Direction, Py};
		Facing == ?DirEast -> {Px + Direction, Py};
		Facing == ?DirNorth -> {Px, Py + Direction};
		Facing == ?DirSouth -> {Px, Py - Direction };
		true -> {Px,Py}
	end.
%%计算目标移动位置
calcDestination(Position, Facing, Direction) ->
	
	{Px, Py} = Position,
	
	if  
		Facing == ?DirWest -> {Px - Direction, Py};
		Facing == ?DirEast -> {Px + Direction, Py};
		Facing == ?DirNorth -> {Px, Py + Direction};
		Facing == ?DirSouth -> {Px, Py - Direction};
		true -> {Px,Py}
	end.

