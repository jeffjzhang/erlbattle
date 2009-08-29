-module(h1.t1).
-compile(export_all).
-include("schema.hrl").
-include("def.hrl").


run(Channel, Side, Queue) ->
	process_flag(trap_exit, true),
	Phone = #phone{channel = Channel, side = Side, queue = Queue},
	SoldierIDs = .lists:map(fun(ID) -> spawn_link(h1.one, start_link, [self(), ID, Phone]) end, ?PreDef_army),
	loop(Channel, SoldierIDs).


loop(Channel, SoldierIDs) ->
	receive
		{'EXIT', Channel, finish} ->
			.lists:foreach(fun(PID) -> exit(PID, finish) end, SoldierIDs);
		_ ->
			loop(Channel, SoldierIDs)
	end.
