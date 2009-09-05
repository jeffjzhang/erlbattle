-module(lxw).
-include("schema.hrl").
-export([run/3,testSpeed/0]).
%以下新思路 未实现
%1、游击战那里人少就打呢
%2、不能让士兵闲着 砍死前面的就判身边有同伴需要帮忙不
%3、四个角比较好肯定不会北部受攻击
run(Channel, Side, Queue) ->
    
	%% 可以不捕获，直接由父进程杀掉
	process_flag(trap_exit, true),
	
	loop(Channel, Side, Queue,1).

loop(Channel, Side, Queue,N) ->
	
	Army = [1,2,3,4,5,6,7,8,9,10],
        %%获取世界时钟
	%%Time = ets:update_counter(battle_timer, clock, 0),
          [{_,Time}|_T] = ets:tab2list(battle_timer),
	lists:foreach(
		fun(Soldier) ->   % 一直朝前， 直到碰到人，然后开始砍	
			case someone_ahead(Soldier,Side) of
				true ->
                                       %% io:format("~n----someone_ahead----------N = ~p s --------------~n", [N]),
                                       %% tools:sleep(50),
					Channel!{command,?ActionAttack,Soldier,Time-1,Soldier};
				false -> 
                                       Channel!{command,?ActionAttack,Soldier,Time,Soldier},
                                        %%case N==0 of 
                                        %%     true ->
                                                %io:format("~n----nnnnnnnnn----------N = ~p s --------------~n", [N]),
                                        %%        Channel!{command,?ActionForward,Soldier,0,random:uniform(3)};
                                        %%    false -> none%Channel!{command,?ActionAttack,Soldier,0,random:uniform(5)}
                                        %%end,

                                        case someone_left(Soldier,Side) of
                                             true ->
                                                  io:format("left Side=~p Soldier=~p.......
                                                     ...........................~n",[Side,Soldier]),
                                                  Channel!{command,?ActionTurnNorth,Soldier,Time-1,Soldier};
                                             false -> 
                                                   case someone_right(Soldier,Side) orelse someone_right2(Soldier,Side) of
                                                            true ->
                                                                  io:format("right Side=~p Soldier=~p.......
                                                                     ............................~n",[Side,Soldier]),
                                                                  Channel!{command,?ActionTurnSouth,Soldier,Time-1,Soldier};
                                                            false ->  %Channel!{command,?ActionAttack,Soldier,0,random:uniform(5)}
                                                                     case N=<3  of 
									     true ->
                                                                                  io:format("N=~p-", [N]),
										  tools:sleep(200),
									          Channel!{command,?ActionForward,Soldier,Time,Soldier};
                                                                                  %tools:sleep(160);
									     false -> 
                                                                                  %%io:format("--N = ~p", [N]), 
                                                                          %%Channel!{command,?ActionAttack,Soldier,0,random:uniform(5)},
						  		          %%Channel!{command,?ActionForward,Soldier,0,Soldier}
                                                                                  %%tools:sleep(70),
                                                                                  Channel!{command,?ActionAttack,Soldier,0,Soldier}
							             end
                                                    end%%none
                                        end;
				%%	
                                none -> none;
				   _ ->
					Channel!{command,?ActionTurnSouth,Soldier,0,Soldier}
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



%% 计算某个角色左边是否有人
someone_left2(SoldierId,Side) ->
	case battlefield:get_soldier(SoldierId,Side) of
		
		none ->  % 角色不存在（已经挂掉了）
			none;
		
		Soldier when is_record(Soldier,soldier) ->  % 找到角色
                        
			Position = left2(Soldier#soldier.position, Soldier#soldier.facing, 1),

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
left2(Position, Facing, Direction) ->
	
	{Px, Py} = Position,
	
	if  
		Facing == ?DirWest -> {Px, Py + 2*Direction};
		Facing == ?DirEast -> {Px, Py - 2*Direction};
		Facing == ?DirNorth -> {Px - 2*Direction, Py};
		Facing == ?DirSouth -> {Px + 2*Direction, Py };
		true -> {Px,Py}
	end.


%%获取右边位置
right(Position, Facing, Direction) ->
	
	{Px, Py} = Position,
	
	if  
		Facing == ?DirWest -> {Px, Py - Direction};
		Facing == ?DirEast -> {Px, Py + Direction};
		Facing == ?DirNorth -> {Px + Direction, Py};
		Facing == ?DirSouth -> {Px - Direction, Py };
		true -> {Px,Py}
	end.
%%获取右前方位置 right_ahead
right_ahead(Position, Facing, Direction) ->
	
	{Px, Py} = Position,
	
	if  
		Facing == ?DirWest -> {Px, Py - Direction};
		Facing == ?DirEast -> {Px, Py + Direction};
		Facing == ?DirNorth -> {Px + Direction, Py};
		Facing == ?DirSouth -> {Px - Direction, Py };
		true -> {Px,Py}
	end.

%%获取右边第二格位置
right2(Position, Facing, Direction) ->
	
	{Px, Py} = Position,
	
	if  
		Facing == ?DirWest -> {Px, Py - 2*Direction};
		Facing == ?DirEast -> {Px, Py + 2*Direction};
		Facing == ?DirNorth -> {Px + 2*Direction, Py};
		Facing == ?DirSouth -> {Px - 2*Direction, Py };
		true -> {Px,Py}
	end.

%% 计算某个角色右边是否有人
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

%% 计算某个角色右边第二格是否有人
someone_right2(SoldierId,Side) ->
	case battlefield:get_soldier(SoldierId,Side) of
		
		none ->  % 角色不存在（已经挂掉了）
			none;
		
		Soldier when is_record(Soldier,soldier) ->  % 找到角色
                        
			Position = right2(Soldier#soldier.position, Soldier#soldier.facing, 1),

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


%% 计算某个角色右前方边是否有人


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


%%获取前边位置
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



	
%% 由于每台机器的运算速度不同，会造成不同的算法在不同的机器上表现不同。 
%% 解决方案是测试某机器运算某个标准行为需要多少时间， 然后以他的倍数来决定主战场sleep 时间	
%% 返回毫秒
testSpeed() ->
	
	Seed = 20, %可以调整这个倍数去控制速度
	
	Times = 10000000,  %  这个运算在w500的机器上大概是2秒。之所以要运算这么多遍，再除seed ,主要要确保每次输出的稳定性。 
	
	
	Begin = tools:getLongDate(),
	testSpeed(Times),
	End = tools:getLongDate(),
	
	Speed = (End - Begin) / 1000 / Seed,

	if 
		Speed < 1 ->
			1;
		true ->
			round(Speed)
	end.

%% 测速算法：做某个行为	; 现在按照list运算和sqrt作为运算标准
testSpeed(Counter) ->
	
	_X = lists:reverse([23,232,43,3,343,34,3,33,4,334,33,44,34,3,33,43,43,2332,2,3,3232,23,2,4343,343,343,334,34343,393]),
	_Y = math:sqrt(9238339),
	
	if 
		Counter > 1 -> testSpeed(Counter - 1);
		true -> true
	end.
		
		
