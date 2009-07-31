-module(ebLogger).
-export([start/0, start/1,
       	stop/0, 
	toLog/4, toLog/5]).

%% 开始日志进程
%% start() -> Pid
start() ->
	register(eb_logger, spawn(fun() -> loop("eb.log") end)).


%% 开始日志进程
%% start(FileName) -> Pid
start(FileName) -> 
	register(eb_logger, spawn(fun() -> loop(FileName) end)).

%% 停止日志进程
%% stop() -> ok
stop() ->
       eb_logger ! {stop},
       ok.


%% 主进程main loop process
%% loop() -> ok
loop(FileName) ->
	receive 
		{stop} ->
			%% TODO: write logs to file
			%% io:format("ebLogger stop!"),
			ok;
		Other ->
			%% todo: receive log to ets table
			io:format("log ~p~n", [Other]),
			loop(FileName)
	end.

%% 写日志
%% toLog(Level, Log) -> ok
%% Types:
%%	Level = atom() :: warn | info | error | fatal | debug
%%	File = string() :: File Name 
%%	Line = int()	:: line number
%%	Log = string()
toLog(Level, File, Line, Log) -> 
	eb_logger ! {Level, Log},
	ok.


%% 写日志
%% toLog(Level, Log, Data) -> ok
%% Types:
%%	Level = atom() :: warn | info | error | fatal | debug
%%	File = string() :: File Name 
%%	Line = int()	:: line number
%%	Log = string()
%%	Data = list()
toLog(Level, File, Line, Log, Data) -> 
	eb_logger ! {Level, Log, Data},
	ok.
