-module(hwh.info).
-compile(export_all).
-include("schema.hrl").
-include("engine/schema.hrl").


start(Master, Side) ->
	process_flag(trap_exit, true),
	Tb = .ets:new(grid, [set, protected, {keypos, #grid_info.id}]),
	init(Tb),
	Master ! {grid, Tb},
	loop(Tb, Side, Master).

init(Tb) ->
	Grids = [{0,0}, {0,1}, {0,2},
		 {1,0}, {1,1}, {1,2},
		 {2,0}, {2,1}, {2,2}],
	.lists:foreach(fun(ID) -> .ets:insert(Tb, #grid_info{id=ID}) end, 
		Grids).


loop(Tb, Side, Master) -> 
	reset(Tb),
	Enemys = .battlefield:get_soldier_by_side(util:enemy(Side)),
	update_grid(Tb, Enemys, #grid_info.enemy),
	Friends = .battlefield:get_soldier_by_side(Side),
	update_grid(Tb, Friends, #grid_info.friend),

	receive
		{'EXIT', Master, finish} -> ok;
		_ -> loop(Tb, Side, Master)
	after 1 -> loop(Tb, Side, Master)
	end.


update_grid(Tb, Soldiers, Key) ->
	.lists:foreach(
		fun(S) ->
			{X, Y} = S#soldier.position,
			ID = {X div 5, Y div 5},
			[Info|_] = .ets:lookup(Tb, ID),
			NewSoldiers = [S#soldier.id|element(Key, Info)],
			.ets:update_element(Tb, ID, {Key, NewSoldiers})
		end,
		Soldiers).


reset(Tb) ->
	Grids = [{0,0}, {0,1}, {0,2},
		 {1,0}, {1,1}, {1,2},
		 {2,0}, {2,1}, {2,2}],
	.lists:foreach(fun(ID) -> .ets:update_element(Tb, ID, {#grid_info.friend, []}) end,
		Grids),
	.lists:foreach(fun(ID) -> .ets:update_element(Tb, ID, {#grid_info.enemy, []}) end, 
		Grids).
