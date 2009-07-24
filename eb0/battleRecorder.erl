-module(battleRecorder).
-export([start/1]).

start(Pid) ->
	
	process_flag(trap_exit, true),
	
	io:format("Battle Recorder Begin to Run ~n",[]),
	
	%% 创建用于缓存回放日志的表
	ets:new(battle_record,[ordered_set,named_table,private]),

	run(Pid,1).

%% 循环等待日子命令	
run(Pid, Seq) ->

	receive
		%% 退出时输出所有缓冲消息
		{'EXIT', Pid , _Msg} ->  
			recordBattle();	
		{Pid,Record} ->
			ets:insert(battle_record, {Seq, Record} ),
			run(Pid, Seq + 1);
		_ ->
			run(Pid,Seq)   %% 其他非法消息扔掉
	end.

%% 将内存中所有记录都输出到文件中
recordBattle() ->
	
	%%提取信息后清除表
	Records = ets:tab2list(battle_record),
	ets:delete(battle_record),
	
	%% open file
	%% Modified by Evan, 2009-07-21
	%% 回放器读取的log文件为warfield.txt，因此直接生成，避免每次改名的麻烦。
	%%{_Ok, Io} = file:open("erlbattle.warlog",[write]),
	{_Ok, Io} = file:open("warfield.txt",[write]),		
	
	%% 初始化战场
	initBattleField(Io),
	
	%% 将内存中的几类记录，按照规范输出
	lists:foreach(
		fun(RawRecord) ->
			{_Seq, Record} = RawRecord,
			case Record of 
				{action, Time, Id, Action, Position, Facing, Hp}->
					{X,Y} = Position,

					io:fwrite(Io,"~p,~p,~p,~p,~p,~p,~p,0~n" , [Time, changeAction(Action), X, Y, uniqueId(Id), simpleDirection(Facing), Hp]);
				{plan, Id, Action, ActionEffectTime} ->
					if 
						Action == "wait"  ->
							io:fwrite(Io,"plan,~p,[]~n" , [uniqueId(Id)]);
						true ->
							io:fwrite(Io,"plan,~p,~p@~p~n" , [uniqueId(Id), changeAction(Action), ActionEffectTime])
					end;
				{status,Time, Id, Position, Facing, Hp, HpLost} ->
					{X,Y} = Position,
					io:fwrite(Io,"~p,~p,~p,~p,~p,~p,~p,~p~n" , [Time,'status', X,Y, uniqueId(Id), simpleDirection(Facing), Hp, HpLost]);
				{result, Result}->
					io:fwrite(Io,"result,~p~n" , [list_to_atom(Result)]);
				_ ->
					none
				end
			end,
			Records),

	%% close file
	file:close(Io).	

%% 输出指令，让双方部队进入战场	
initBattleField(Io) ->

	Army = [1,2,3,4,5,6,7,8,9,10],
	
	%% 准备红方位置
	lists:foreach(
		fun(Id) ->
			io:fwrite(Io,"~p,~p,~p,~p,~p,~p,~p,~p~n" , [0,'stand', 0,1+Id, Id, 'e', 100, 0])
		end,
		Army),

	%% 准备蓝方位置
	lists:foreach(
		fun(Id) ->
			io:fwrite(Io,"~p,~p,~p,~p,~p,~p,~p,~p~n" , [0,'stand', 14,1+Id, Id+10, 'w', 100, 0])
		end,
		Army).
		
			
%% record 输出协议要求蓝方按照 id =10 输出
uniqueId(Id) ->

	{Sid, Side} = Id,
	
	if 
		Side == "blue" ->
			Sid + 10;
		true ->
			Sid
	end.

%% 动作转码	
changeAction(Action) ->	
	if
		Action == "move" -> 'walk';
		Action == "forward" -> 'walk';
		Action == "attack" -> 'fight';
		Action == "back" -> 'back';
		Action == "turnEast" -> 'turnEast';
		Action == "turnWest" -> 'turnWest';
		Action == "turnSouth" -> 'turnSouth';
		Action == "turnNorth" -> 'turnNorth';
		true -> list_to_atom(Action)
	end.
	
	
%% 方向转码
simpleDirection(Facing) ->

	if
		Facing == "west" ->'w';
		Facing == "east" ->'e';
		Facing == "north" ->'n';
		Facing == "south" ->'s'
	end.
	