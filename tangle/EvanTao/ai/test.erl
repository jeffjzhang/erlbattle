-module(test).
-include("schema.hrl").

%% 外部调用
-export([run/3]).

%% start_pos = {X, Y}   开始位置
%% stop_pos = {X, Y}    目标位置
%% path_col = path_row = [] 路径的X集合和Y集合
-record(path_array, {start_pos, stop_pos, path_col, path_row}).

run(ChannelProc, Side, CmdQueue) ->
    process_flag(trap_exit, true),
    
    

    loop().

loop() ->
    
    receive
        {'EXIT', _From, _Reason} ->
            io:format("==== ai army go home~~~~~~~n");
            
        _Other ->
            loop()
    
        after 10 ->
            loop()
    end.ai.erl

build_path() ->
    none.
