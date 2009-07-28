-module(feardFarmers).
-export([run/3]).

%% 这是一个最简单的例子
%% 农民们吓的除了呻吟，什么战斗指令都没有发出去。原地不动等着别人屠杀
run(Channel, Side, Queue) ->
	
	io:format("don't kill us , we are poor farmers ~n",[]),
	
	tools:sleep(1000),
	
	run(Channel,Side, Queue).
	