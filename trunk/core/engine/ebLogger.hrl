%% 日志记录
-record(log_record, {number,        %% 序列号
		     level,         %% 日志级别
		     time,          %% 时间
		     file_name,     %% 输入日志的文件名
		     line,          %% 输入日志的行号
		     content}       %% 日志内容
       ).

%% info macro
-define(info(Log), fun() -> ebLogger:toLog(info, ?FILE, ?LINE, Log) end()).
-define(info2(ProcName, Log), fun() -> ebLogger:toLog(ProcName, info, ?FILE, ?LINE, Log) end()).

%% warn macro
-define(warn(Log), fun() -> ebLogger:toLog(warn, ?FILE, ?LINE, Log) end()).
-define(warn2(ProcName, Log), fun() -> ebLogger:toLog(ProcName, warn, ?FILE, ?LINE, Log) end()).

%% error macro
-define(error(Log), fun() -> ebLogger:toLog(error, ?FILE, ?LINE, Log) end()).
-define(error2(ProcName, Log), fun() -> ebLogger:toLog(ProcName, error, ?FILE, ?LINE, Log) end()).

%% fatal macro
-define(fatal(Log), fun() -> ebLogger:toLog(fatal, ?FILE, ?LINE, Log) end()).
-define(fatal2(ProcName, Log), fun() -> ebLogger:toLog(ProcName, fatal, ?FILE, ?LINE, Log) end()).

%% debug macro
-define(debug(Log), fun() -> ebLogger:toLog(debug, ?FILE, ?LINE, Log) end()).
-define(debug2(ProcName, Log), fun() -> ebLogger:toLog(ProcName, debug, ?FILE, ?LINE, Log) end()).

