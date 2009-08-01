%% 神经系统
%% 检查动作完成情况

-module(nervous).
-include("schema.hrl").

-export([start/3]).

start(Soldier, CmdQueue, CarebelProc) ->
    process_flag(trap_exit, true),

    loop(CarebelProc, Soldier, CmdQueue).

loop(CarebelProc, Soldier, CmdQueue) ->
    send_msg(CarebelProc, Soldier, CmdQueue),
    
    receive
        {'EXIT', _From, _Reason} ->
            {SoldierId, _Side} = Soldier#soldier.id,
            io:format("   = nervous[~p] exited~n", [SoldierId]);
            
        _Other ->
            loop(CarebelProc, Soldier, CmdQueue)
            
    after 50 ->
        loop(CarebelProc, Soldier, CmdQueue)
    end.

%% 发送动作完成消息
send_msg(CarebelProc, Soldier, CmdQueue) ->
    case get_action_status(Soldier, CmdQueue) of
        'ActionDone' ->
            CarebelProc ! 'ActionDone';
         
        'ActionDoing' ->
            CarebelProc ! 'ActionDoing';
            
        'DestUnreachable' ->
            CarebelProc ! 'DestUnreachable';
        
        _default ->
            none
    end.

%% 检测动作
%% ActionDone 动作完成
%% ActionDoing 动作正在进行

%% 只检查动作是否完成。
get_action_status(Soldier, CmdQueue) ->
    {SoldierId, Side} = Soldier#soldier.id,
    CmdInfo = baiqi_tools:get_soldier_cmd(SoldierId, CmdQueue),
    Soldier_we = baiqi_tools:get_soldier_by_id_side(SoldierId, Side),
    if 
        CmdInfo == [] ->  %% 命令队列中无此战士的命令
            if
                Soldier_we == none ->  %% 战场中无此战士
                    none;
                    
                true -> %% 找到战士
                    case Soldier_we#soldier.action of
                        "wait" ->
                            'ActionDone';
                        
                        _Other ->
                            none
                    end
                    
            end;
            
        true -> %% 队列中已有此战士的命令
                %% 每个战士的队列长度为1，则此命令还未执行。再次发送则会冲掉此命令。
            %io:format("cmd[~p] is in queue~n", [CmdInfo#command.name]),
            'ActionDoing'
            
    end.

