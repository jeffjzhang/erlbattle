-module(tools).
-export([sleep/1,getLongDate/0]).

%% Sleep 工具函数
sleep(Sleep) ->
	receive
	
	after Sleep -> true
    
	end.
	
getLongDate() ->
	{MegaSecs, Secs, MicroSecs} = now(),
	Seed = 1000 * 1000,
	(MegaSecs * Seed + Secs) *Seed + MicroSecs.
	
