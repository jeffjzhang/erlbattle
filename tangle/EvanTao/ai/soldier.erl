-module(soldier).

%% 外部调用
-export([start/1]).


%% SoldierInfo = {ChannelProc, Id, Side}
start(SoldierInfo) ->
    %{ChannelProc, SoldierId, Side} = SoldierInfo,
    process_flag(trap_exit, true),
    
    loop(SoldierInfo),
    none.
    
%% ChannelProc ! {command, Cmd, SoldierId, 0, get_random_seq()};    
    
%% 接口函数
%% 移动
%% 向8个方向移动一步
move(Position) ->
    none.

%% 攻击
attack() ->
    none.


%% 主循环    
loop(SoldierInfo) ->
    {ChannelProc, SoldierId, Side} = SoldierInfo,
    receive
        {'EXIT', _From, _Reason} ->
            io:format("==== ai soldier[~p]~~~~~~~n", [SoldierId]);
            
        _Other ->
            loop(SoldierInfo)
    
        after 100 ->
            loop(SoldierInfo)
    end.
    