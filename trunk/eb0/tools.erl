-module(tools).
-export([sleep/1]).

%% Sleep ¹¤¾ßº¯Êı
sleep(Sleep) ->
	receive
	
	after Sleep -> true
    
	end.