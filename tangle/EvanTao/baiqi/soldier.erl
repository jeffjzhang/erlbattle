%% 战士进程
%% 生成2个进程，cerebel小脑负责发出命令，nervous神经检查命令执行情况

%% 本身具有2个动作
%% move(point):     移动到某一点{x, y}
%% attack(point):  攻击某一点{x, y}
%% 本身知道怎么将这2个动作分解成标准的forward等8个动作(由cereble分解, nervous执行)

%% 上级会将一系列的这2个动作发过来，让战士执行
%% 如：
%%   1 移动到A点
%%   2 移动到B点
%%   3 攻击C点

%% attack(point):   战士自主选择路线进行攻击

-module(soldier).
-include("schema.hrl").

-export([start/3]).

start(Soldier, ChannelProc, CmdQueue) ->
    process_flag(trap_exit, true),
    
    CerebelProc = spawn_link(cerebel, start, [Soldier, ChannelProc]),
    spawn_link(nervous, start, [Soldier, CmdQueue, CerebelProc]),
    
    {SoldierId, _Side} = Soldier#soldier.id,
    loop(SoldierId, CerebelProc).

loop(SoldierId, CerebelProc) ->
    receive
        {'Move', Position, CmdSender} ->
            loop(SoldierId, CerebelProc);
            
        {'Attack', SoldierEnemy, CmdSender} ->
            CerebelProc ! {'Attack', SoldierEnemy, CmdSender},
            
            loop(SoldierId, CerebelProc);
            
        {'EXIT', _From, _Reason} ->
            io:format("   = soldier[~p] exited~n", [SoldierId]);

        _Other ->
            loop(SoldierId, CerebelProc)
            
    after 10 ->
        loop(SoldierId, CerebelProc)
    end.

