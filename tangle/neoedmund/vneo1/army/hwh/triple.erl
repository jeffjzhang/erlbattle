-module(hwh.triple).
-compile(export_all).
-include("schema.hrl").


%%指挥总表
%%fm_pos, 阵型
%%{pursue, soldierid}, 自由追击的战士


run(Channel, Side, Queue) ->
	process_flag(trap_exit,true),
	Master = self(),
	InfoTb = .ets:new(info, [set, protected]),

	%%信息收集进程
	Info = spawn_link(hwh.info, start, [Master, Side]),
	receive
		{grid, Grid} -> ok
	end,
	Phone = #phone{channel=Channel, info=InfoTb, side=Side, queue=Queue, grid=Grid},

	%%分布追击进程
	ScatterL = .lists:map(
		fun(Y) ->
			spawn_link(hwh.scatter, start, [Master, Y, Phone])
		end,
		[0,1,2]),

	%%阵型和战士进程
	FM = spawn_link(hwh.fm, start, [Master, Phone, random2]),
	SoldierList = .lists:map(
		fun(ID) ->
			spawn_link(hwh.one, start, [Master, Phone, {ID, Side}, hold])
		end,
		[1,2,3,4,5,6,7,8,9,10]),
	loop(Channel, .lists:merge([FM, Info], ScatterL), SoldierList, Phone).


loop(Channel, Childs, SoldierList, Phone) ->
	receive
		{'EXIT', Channel, finish}  -> 
			.lists:foreach(fun(PID) -> exit(PID, finish) end, Childs),
			.lists:foreach(fun(PID) -> exit(PID, finish) end, SoldierList);
		
		{set_fm, _FM, PosList} -> 
			Tb = Phone#phone.info,
			.ets:insert(Tb, {fm_pos, PosList}),
			loop(Channel, Childs, SoldierList, Phone);
		
		{set_attack, _FM} ->
			Master = self(),
			.lists:foreach(fun(PID) -> PID ! {set, Master, attack} end, SoldierList),
			loop(Channel, Childs, SoldierList, Phone);

		{pursue, _Scatter, ID} ->
			Tb = Phone#phone.info,
			.ets:insert(Tb, {{pursue, ID}, 1}),
			loop(Channel, Childs, SoldierList, Phone);
		
		_ -> loop(Channel, Childs, SoldierList, Phone)
	end.
