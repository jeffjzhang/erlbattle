-module(tests).
-export([testTimer/0]).

testTimer() ->
	gm:init(),
	T=ui:gettime(),
	io:format("~w~n",[T]),
	tools:sleep(100),
	io:format("~w ~w ~w~n",[ui:gettime(), ui:gettime(), ui:gettime()]),
	tools:sleep(100),
	io:format("~w ~w ~w~n",[ui:gettime(), ui:gettime(), ui:gettime()]),
	tools:sleep(1000),
	io:format("~w ~w ~w~n",[ui:gettime(), ui:gettime(), ui:gettime()]),
	tools:sleep(1000),
	io:format("~w ~w ~w~n",[ui:gettime(), ui:gettime(), ui:gettime()]),
	io:format("end.").

