% by neoedmund@gmail rev 0.1
% 

-module(neoe).
-include("schema.hrl").
-export([run/3]).

debug(S) ->
	io:format("[neoe]~w~n",[S]).

	
run(Com, Side, Queue) ->
	process_flag(trap_exit, true),
	
	debug({'燕人张飞在此 my side is ', Side}),
	%% register(nextNum, spawn( fun() -> nextNum(0) end)),
	[A|B]=? PreDef_army,
	debug(A),
	debug(B),
	% one man is go out
	spawn(fun() -> go1(A, Com, Side) end),
	% the others hold
	lists:foreach(
		fun(Man) ->   
			spawn(fun()-> go2(Man, Com,Side) end)
		end,
		B),
	debug('10 man is alive'),
	% kill myself
	receive
		{'EXIT', _Where, _Reason} ->  
			debug({'game is over.', _Where, _Reason})
		% AnyThing -> debug(AnyThing)	
	end.		
			

	
nextNum(Num) ->
	receive
		{Pidx} ->
			Pidx ! Num,
			nextNum(Num+1)
	end.		
com(Com, C) ->
	debug({'send ', C}),
	Com ! C.
go1(Man, Com, Side) ->
	turnBack(Man, Com, Side),
	case someoneAhead1(Man,Side) of
		true ->
			com(Com, {command,?ActionAttack,Man,0,0});
		false ->
			com(Com, {command,?ActionForward,Man,0,0});
		_ ->
			none
	end,
	waitSec(),
	go1(Man, Com,Side).
go2(Man, Com, Side) ->
	turnBack(Man, Com, Side),
	case someoneAhead2(Man,Side) of
		true ->
			com(Com, {command,?ActionAttack,Man,0,0});
		false ->
			com(Com, {command,?ActionForward,Man,0,0});
		_ ->
			none
	end,
	waitSec(),
	go2(Man, Com,Side).	
turnBack(Man, Com, Side) ->
	A=battlefield:get_soldier(Man,Side),
	if A /= none ->
		{X1,Y1}=A#soldier.position,
		D=A#soldier.facing,
		debug({D,X1,Y1}),
		if (D==?DirWest) and (X1==1) ->
				com(Com, {command,?ActionTurnEast,Man,0,0}),
				waitSec(),
				com(Com, {command,?ActionTurnEast,Man,0,0}),
				waitSec();
		true ->
			if (D==?DirEast) and (X1==13) ->
				com(Com, {command,?ActionTurnWest,Man,0,0}),
				waitSec(),
				com(Com, {command,?ActionTurnWest,Man,0,0}),
				waitSec();
			true -> none	
			end
		end;
	true->none	
	end.
		
		
go(Man, Com) ->
	X1 = isFacingEnemy(),
	if 
		X1 == true ->		
			com(Com, {command,?ActionAttack,Man,0,0});
		true ->
			com(Com, {command,?ActionForward,Man,0,0})
	end,		
	waitSec(),
	go(Man, Com).
	
waitSec() ->
	T1 = erlbattle:getTime(),
	waitSec(T1+1).
waitSec(T1) ->
	T2 = erlbattle:getTime(),
	if T2<T1 ->
		sleep(100),
		waitSec(T1);
	true -> none
	end.

isFacingEnemy() ->
	true.

sleep(T) ->
	receive
	after T -> true
	end.
	
someoneAhead1(SoldierId,Side) ->
	
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
someoneAhead2(SoldierId,Side) ->
	
	case battlefield:get_soldier(SoldierId,Side) of
		
		none ->  % 角色不存在（已经挂掉了）
			none;
		
		Soldier when is_record(Soldier,soldier) ->  % 找到角色

			Position1 = erlbattle:calcDestination(Soldier#soldier.position, Soldier#soldier.facing, 1),
			Position2 = erlbattle:calcDestination(Soldier#soldier.position, Soldier#soldier.facing, 2),
			Position3 = erlbattle:calcDestination(Soldier#soldier.position, Soldier#soldier.facing, 3),
			A = battlefield:get_soldier_by_position(Position1),
			B = battlefield:get_soldier_by_position(Position2),
			C = battlefield:get_soldier_by_position(Position3),
			if (A /= none) or (B /= none) or (C /= none)->
				true;
			true -> false
			end;
		_->
			none
	end.		

