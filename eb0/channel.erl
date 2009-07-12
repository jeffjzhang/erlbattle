-module(channel).
-export([start/3]).
-include("schema.hrl").

start(BattleField, Side, ArmyName) ->
	
	process_flag(trap_exit,true),
	
	receive
		
		%% 等待主程序将消息队列控制权转过来，然后启动指挥程序
		{'ETS-TRANSFER',Tab,_FromPid,_GiftData} ->
			io:format("~p plays the ~p Side ~n", [ArmyName, Side]),
			Commander = spawn_link(ArmyName, run, [self(),Side]),
			loop(BattleField, Commander, Tab,1);
		
		_ ->
			start(BattleField, Side, ArmyName)
			
	end.	
	
%% 消息循环，将指令放到队列中
loop(BattleField, Commander, Queue,CommandId) ->
	
	receive
		
		{command,Command,Soldier,Time} ->
			%% 生成一个command 记录
			CmdRec = #command{
					soldier_id = Soldier,
					name = Command,
					execute_time = Time,
					seq_id = CommandId},
			ets:insert(Queue, CmdRec),
			loop(BattleField, Commander, Queue,CommandId +1);

		%% 主程序运行完后，会发出清除已经使用过的命令的消息，需要将其清除，避免重复命令
		%% 如果在清除之前，已经有新的消息进来，其seq_id 已经更新，就不会被误删
		{expireCommand, CommandIds} ->
			io:format("begin to clear used command ~p.of ~p. ~n",  [CommandIds, ets:tab2list(Queue)]),
			lists:foreach(
				fun(SeqId) ->
					Pattern=#command{
						soldier_id = '_',
						name = '_',
						execute_time = '_',
						seq_id = SeqId},
					ets:match_delete(Queue, Pattern)
				end,
				CommandIds),
			io:format("cleard after of ~p. ~n",  [ets:tab2list(Queue)]),
			loop(BattleField, Commander, Queue,CommandId);
			
		%% 主程序开始杀我，我就杀玩家进程
		{'EXIT', _, _} ->
			exit(Commander, finish), %杀决策进程, 决策进程如果不捕捉，就自动退出
			tools:sleep(500),
			ets:delete(Queue) % 清除队列
	end.
	
	
	





