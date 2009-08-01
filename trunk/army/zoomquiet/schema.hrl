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
		%% 格式为字符串
		action,

		%%动作生效时间
		act_effect_time,

		%%行动次序,用于控制同一节拍行动的前后顺序
	    act_sequence	
	}).

%% 命令记录
-record(command, {

		%% 战士号，不用带side
		soldier_id, 

		%% 指令名称，格式为字符串
		name,

		%% 要求执行时间
		execute_time,

		%% 行动次序 = 战士的行动次序
		execute_seq,

		%% 任务序号，用于识别哪些指令被执行过，以便清除
		%% 指挥官不用设置此字段，这个是管理程序使用的。
		seq_id

	}).
