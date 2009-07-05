
-record(soldier,{
		
		%%战士编号, tuple形式{编号,所属战队}
		id, 
		
		%%位置
		position,
		
		%%血量 0 - 100
		hp,
		
		%%面朝方向
		%%north,west,south,east
		facing,
		
		%%当前动作
		%% 前进forward, 后退 back, 
		%% 转向 turnSouth, turnNorth, turnWest,turnEast
		%% 攻击 attack
		%% 原地待命 wait 
		action,
		
		%%动作生效时间
		act_effect_time,
		
		%%行动次序(目前未理解其作用)
	    act_sequence	
	}).

%% 命令记录
-record(command, {warrior_id, command_name, execute_time}).
