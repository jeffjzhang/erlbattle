%% info macro
%% info 宏
-define(info(Log), fun() -> ebLogger:toLog(info, ?FILE, ?LINE, Log) end()).
-define(info2(Log, Data), fun() -> ebLogger:toLog(info, ?FILE, ?LINE, Log, Data) end()).

%% warn macro
-define(warn(Log), fun() -> ebLogger:toLog(warn, ?FILE, ?LINE, Log) end()).
-define(warn2(Log, Data), fun() -> ebLogger:toLog(warn, ?FILE, ?LINE, Log, Data) end()).

%% error macro
-define(error(Log), fun() -> ebLogger:toLog(error, ?FILE, ?LINE, Log) end()).
-define(error2(Log, Data), fun() -> ebLogger:toLog(error, ?FILE, ?LINE, Log, Data) end()).

%% fatal macro
-define(fatal(Log), fun() -> ebLogger:toLog(fatal, ?FILE, ?LINE, Log) end()).
-define(fatal2(Log, Data), fun() -> ebLogger:toLog(fatal, ?FILE, ?LINE, Log, Data) end()).

%% debug macro
-define(debug(Log), fun() -> ebLogger:toLog(debug, ?FILE, ?LINE, Log) end()).
-define(debug2(Log, Data), fun() -> ebLogger:toLog(debug, ?FILE, ?LINE, Log, Data) end()).

