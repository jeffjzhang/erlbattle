-module(testEbLogger).
-export([test/0]).
-include("test.hrl").
-include("schema.hrl").

%% 注：关于日志记录的格式，请参见ebLogger.hrl中的log_record记录的结构

test() ->
    %% 启动默认的日志记录器，会生成日志文件eb.log
    ebLogger:start(),
    
    %% 同时启动一个专用的日志记录器，会生成一个日志文件testEbLogger.log
    %% 这个主要应用于army们生成自己的日志文件，便于分析自己的army运行情况
    ebLogger:start("testEbLogger", test_eb_logger),
    
    %% 向默认的日志记录器中写入info信息
    ?info("This is a info log message"),
    %% 向专用的日志记录器中写入info信息
    ?info2(test_eb_logger, "This is a info log"),
    
    %% 向默认的日志记录器中写入warn信息
    ?warn("This is a info log message"),
    %% 向专用的日志记录器中写入warn信息
    ?warn2(test_eb_logger, "This is a info log"),
    
    %% 向默认的日志记录器中写入error信息
    ?error("This is a info log message"),
    %% 向专用的日志记录器中写入error信息
    ?error2(test_eb_logger, "This is a info log"),
    
    %% 向默认的日志记录器中写入fatal信息
    ?fatal("This is a info log message"),
    %% 向专用的日志记录器中写入fatal信息 
   ?fatal2(test_eb_logger, "This is a info log"),
    
    %% 向默认的日志记录器中写入debug信息
    ?debug("This is a info log message"),
    %% 向专用的日志记录器中写入debug信息
    ?debug2(test_eb_logger, "This is a info log"),
  
    %% 停止默认的日志记录器，此时将日志写入文件
    ebLogger:stop(),
    %% 停止专用的日志记录器，此时将日志写入文件
    ebLogger:stop(test_eb_logger).
    



