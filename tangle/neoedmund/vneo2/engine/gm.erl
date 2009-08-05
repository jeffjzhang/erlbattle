-module(gm).
-export([init/0]).

% game master

init() ->
	register(timer, spawn(fun()-> timer(0) end)),
	io:format("init end~n").

timer(N) ->
	receive
		{get, Pid} ->
			Pid ! N,
			timer(N);
		Other -> io:format("timer:what? ~w~n",[Other])
	after
		10 ->
			timer(N+1)
	end.
