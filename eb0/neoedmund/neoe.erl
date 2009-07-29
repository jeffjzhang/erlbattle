% by neoedmund@gmail rev 0.1
% this program is under development, can not be used.

-module(neoe).
-include("schema.hrl").
-export([run/3]).

run(Channel, Side, Queue) ->
	io:format("[neoe]my side is ~w~n",[list_to_atom(Side)]),
	register(nextNum, spawn( fun() -> nextNum(0) end)),
	loop(Channel, Side, Queue).
	
nextNum(Num) ->
	receive
		{Pidx} ->
			Pidx ! Num,
			nextNum(Num+1)
	end.		
			

loop(Channel, Side, Queue) ->
	nextNum ! {self()},
	receive	
		Num ->
			MyNum = Num
	end,
	
	io:format("[~w]run ~w~n",[MyNum, list_to_atom(Side)]),
	
	Army = [1,2,3,4,5,6,7,8,9,10],
	
	lists:foreach(
		fun(Soldier) ->   % 一直朝前， 直到碰到人，然后开始砍	
			case someoneAhead(Soldier,Side) of
				true ->
					io:format("[~w] send command 1 ~n",[MyNum]),
					Channel!{command,"attack",Soldier,0,random:uniform(5)};
				false ->
					io:format("[~w] send command 2 ~n",[MyNum]),
					Channel!{command,"forward",Soldier,0,random:uniform(3)};
				_ ->
					none
			end
		end,
		Army),
	
	%loop(Channel, Side, Queue),
	receive
		after 200 -> 
			io:format("[~w] i loop here~n",[MyNum]),
			loop(Channel, Side, Queue),
			io:format("[~w]can i reach here?~n",[MyNum])
	end,
	io:format("[~w]function exit~n",[MyNum]).
	



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
					
			
			
	



	
