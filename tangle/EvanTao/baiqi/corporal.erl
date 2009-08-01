%%% 通讯官进程。
%%% 负责将指挥官的命令分解成战术层次的一系列命令
%%% 如先到A点，再到B点等

-module(corporal).
-include("schema.hrl").
-include("baiqi.hrl").

-export([start/3]).

start(CommanderProc, Side, Army) ->
    process_flag(trap_exit, true),
    
    loop(CommanderProc, Side, Army).

%% 接收指挥官发来的命令，分解命令，给战士发出命令
%% 接收战士/队长反馈的消息，进行处理，并指挥战士/队长
loop(CommanderProc, Side, Army) ->
    receive
        %% 指挥官发来“自由攻击”命令
        %% 给每个战士选择敌人，并给战士发出attack/1指令
        {'AttackAuto', CommanderProc} ->
            attack_auto(Side, Army),

            loop(CommanderProc, Side, Army);

        {'EXIT', _From, _Reason} ->
            io:format("   = corporal exited~n");

        _Other ->
            loop(CommanderProc, Side, Army)

        after 10 ->
            loop(CommanderProc, Side, Army)
    end.

attack_auto(Side, Army) ->
    lists:foreach(
        fun(Soldier_baiqi) ->
            %% 随机找出敌人
            %%   找出所有敌人
            EnemySide = if
                            Side == "red"   -> "blue";
                            true            -> "red"
                        end,
            EnemyArmy = baiqi_tools:get_soldier_by_side(EnemySide),
            
            %%   随机抽取
            EnemySoldier = lists:nth(baiqi_tools:get_random(length(EnemyArmy)), EnemyArmy),
            % {soldier,{6,"blue"},{14,7},100,"west","wait",0,0}

            %% 指挥该战士攻击
            Soldier_baiqi#soldier_baiqi.pid ! {'Attack', EnemySoldier, self()}
        end,
        Army).
