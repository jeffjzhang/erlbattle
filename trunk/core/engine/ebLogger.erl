-module(ebLogger).
-export([start/0, start/2,
	 stop/0, stop/1,
	toLog/4, toLog/5]).
-include("ebLogger.hrl").
		     
%% 开始日志进程
%% start() -> Pid
start() ->
    case whereis(eb_logger) of
	undefined -> register(eb_logger, spawn(fun() -> loop(eb_logger, "eb.log") end));
	Pid  -> Pid
    end.

%% 结束日志进程
%% stop() -> ok
stop() ->
    eb_logger ! {stop},
    ok.

%% 这个函数的目的是让一个军队创建一个自己的日志进程，写一个单独的日志文件，这样有利于分配程序
%% 开始日志进程
%% start(ModelName, ProcName) -> Pid
%% Types:
%%     ModelName = string()  模块名称，会被存储为日志文件名
%%     PrcName = atom()      进程注册名称，是一个原子。要避免重名。
start(ModelName, ProcName) -> 
    case whereis(ProcName) of
	undefined -> register(ProcName, spawn(fun() -> loop(ProcName, ModelName++".log") end));
	Pid -> Pid
    end.

%% 结束日志进程，对应上面的start
%% stop(ProcName) -> ok
%% Types:
%%     ProcName = atom()     是start时指定的进程注册的名字
stop(ProcName) ->
    ProcName ! {stop},
    ok.

%% 主进程main loop process
%% loop(ProcName, FileName) -> ok
loop(ProcName, FileName) ->
    %% 用进程名（原子）当表名
    Tid = ets:new(ProcName, [ordered_set, private, {keypos, #log_record.number}]),
    loop(Tid, FileName, 1).

%% loop(Tid, FileName, Number) -> ok
loop(Tid, FileName, Number) ->
    receive 
	%% 结束了，将日志写到文件中
	{stop} ->
	    write_log_to_file(Tid, FileName);
	%% 记录日志到数据表中
	{Level, File, Line, Log} ->
	    ets:insert(Tid, #log_record{
			 number = Number,
			 level = Level,
			 time = now(),
			 file_name = File,
			 line = Line,
			 content = Log
			}
		      ),
	    loop(Tid, FileName, Number+1)
    end.

%% 写日志
%% toLog(Level, Log) -> ok
%% Types:
%%	Level = atom() :: warn | info | error | fatal | debug
%%	File = string() :: File Name 
%%	Line = int()	:: line number
%%	Log = string()
toLog(Level, File, Line, Log) -> 
    eb_logger ! {Level, File, Line, Log},
    ok.


%% 写日志
%% toLog(ProcName, Level, Log) -> ok
%% Types:
%%      ProcName = atom() :: 注册的进程名
%%	Level = atom()    :: 日志级别warn | info | error | fatal | debug
%%	File = string()   :: File Name 
%%	Line = int()	  :: line number
%%	Log = string()
toLog(ProcName, Level, File, Line, Log) -> 
    ProcName ! {Level, File, Line, Log},
    ok.


%% write_log_to_file(Tid, FileName) -> ok
%% Tid = atom()
%% FileName = string()
write_log_to_file(Tid, FileName) ->
    case ets:first(Tid) of 
	'$end_of_table' ->
	    ok;
	K  ->
	    {ok, F} = file:open(FileName, write),
	    write_log_to_file(Tid, F, K)
    end.

%% write_log_to_file(Tid, File, Key) -> ok
write_log_to_file(Tid, File, Key) ->
    Rec = ets:lookup(Tid, Key),
    io:format(File, "~p~n", Rec),
    case ets:next(Tid, Key) of 
	'$end_of_table' ->
	    file:close(File),
	    ok;
	K -> 
	    write_log_to_file(Tid, File, K)
    end.
    
    
