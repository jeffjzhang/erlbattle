-define(PreDef_army, [1,2,3,4,5,6,7,8,9,10]).

-record(chess,{
		id,
		army,
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
		Action == forward  -> 200;
		Action == back -> 400;
		Action == turnSouth -> 100;
		Action == turnWest -> 100;
		Action == turnEast -> 100;
		Action == turnNorth -> 100;
		Action == attack -> 200;
		true ->
			io:format("bad Action ~w~n",[Action]),
			0
	end.


