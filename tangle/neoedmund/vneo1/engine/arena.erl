-module(arena).
-export([run/0]).


run() ->
	Army = array:from_list([englandArmy,feardFarmers,hwh.triple,lxw,madDog,neoe,randomArmy,soldierGo]),
	Size = array:size(Army),
	{_Ok, Io} = file:open("autoRound.cmd",[write, {encoding, utf8}]),
	for(0, Size-2, fun(X) ->
		for(X+1, Size-1, fun(Y) ->
			A =array:get(X, Army),
			B =array:get(Y, Army),
			Fn=lists:concat(["b_",atom_to_list(A), "_", atom_to_list(B), ".log"]),
			io:format("~w VS ~w to ~w ~n",[A,B,list_to_atom(Fn)]),			
			% spawn(erlbattle,start,[A,B,{none,10,Fn}]) % you cannot use it now because ets name table
			_Node=lists:concat(["N",atom_to_list(A), "_", atom_to_list(B), "@localhost"]),
			% rpc:call(Node, erlbattle,start,[A,B,{none,10,Fn}])
			io:fwrite(Io,"erl -pz ebin -eval erlbattle:start(~w,~w,{none,10,~w})~n" , [A,B,Fn])
			% io:fwrite(Io,"start java -cp ../ebrep-bin/neoeebrep.jar neoe.ebrep.Main " , [A,B,Fn])
			
			end)
		end),
	file:close(Io),	
	io:format("arena finish~n").	
	
for(A,B,F) ->
	if A =< B ->
		F(A),
		for(A+1, B, F);
	true -> true
	end.
			
	
