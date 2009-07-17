-module(tools).
-export([sleep/1]).

%% Sleep 工具函数
sleep(Sleep) ->
	receive
	
	after Sleep -> true
    
	end.