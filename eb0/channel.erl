-module(channel).
-export([start/3]).
-include("schema.hrl").

start(BattleField, Side, ArmyName) ->
	
	process_flag(trap_exit,true),
	
	%% 创建通讯队列
	Queue = ets:new(queue, [protected, {keypos, #command.soldier_id}]),	
	
	%%启动玩家指挥程序
	Commander = spawn_link(ArmyName, run, [self(),Side,Queue]),
	
	%%将queue 的句柄通过消息，发回给主程序
	BattleField ! {queue,self(), Queue},
	
	loop(BattleField, Commander, Queue,1).
	
%% 消息循环，将指令放到队列中
loop(BattleField, Commander, Queue,CommandId) ->
	
	receive
		
		{command,Command,Soldier,Time,Seq} ->
			
			%% 生成一个command 记录; 指令必须合法，否则忽略
			case erlbattle:actionValid(Command) andalso erlbattle:soldierValid(Soldier) of

				true ->
					CmdRec = #command{
							soldier_id = Soldier,
							name = Command,
							execute_time = Time,
							execute_seq = Seq,
							seq_id = CommandId},
					ets:insert(Queue, CmdRec);
				_Else -> none
			end,					
			loop(BattleField, Commander, Queue,CommandId +1);

		%% 主程序运行完后，会发出清除已经使用过的命令的消息，需要将其清除，避免重复命令
		%% 如果在清除之前，已经有新的消息进来，其seq_id 已经更新，就不会被误删
		{expireCommand, CommandIds} ->

			lists:foreach(
				fun(SeqId) ->
					Pattern=#command{
						soldier_id = '_',
						name = '_',
						execute_time = '_',
						execute_seq = '_',
						seq_id = SeqId},
					ets:match_delete(Queue, Pattern)
				end,
				CommandIds),

			loop(BattleField, Commander, Queue,CommandId);
			
		%% 主程序开始杀我，我就杀玩家进程
		%% 注意只接受来自主程序的exit 指令，不接受其他来源
		{'EXIT', BattleField, _B} ->
			exit(Commander, finish), %杀决策进程, 决策进程如果不捕捉，就自动退出
			tools:sleep(500),
			ets:delete(Queue); % 清除队列
			
		_Else ->
			loop(BattleField, Commander, Queue,CommandId)
		
	end.
	
	
	





