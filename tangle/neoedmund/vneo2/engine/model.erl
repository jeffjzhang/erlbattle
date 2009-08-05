-module(model).

-record(chess,{
		id,
		army,
		type, % 兵种：步兵 footman 骑兵 knight 弓弩兵 archer 
		x,y,
		hp,
%north,west,south,east
		facing,
%% 前进forward, 后退 back, 转向 turnSouth, turnNorth, turnWest,turnEast 攻击 attack 原地待命 wait(不发送也可以)
		action,
		%%动作生效时间
		act_effect_time
		}).

%% 命令记录
-record(command, {
		%% 战士号，不用带side
		chessid,
		%% 指令名称，格式为字符串
		name,		
		sentTime,
		execTime
	}).

getCooldownTime(Action) ->
	if
		Action == forward  -> 20;
		Action == back -> 40;
		Action == turnSouth -> 10;
		Action == turnWest -> 10;
		Action == turnEast -> 10;
		Action == turnNorth -> 10;
		Action == attack -> 20;
		true ->
			io:format("bad Action ~w~n",[Action]),
			0
	end.


