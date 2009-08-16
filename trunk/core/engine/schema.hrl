%% 关于日志记录器的内容
-include("core/engine/ebLogger.hrl").

%% 战场最多运行的次数 
-define(MaxEBTurn, 1000).   

%% 战士数组
%% 同时是战士编号
-define(PreDef_army, [1,2,3,4,5,6,7,8,9,10]).

%% 对战双方
-define(RedSide, red).
-define(BlueSide, blue).

%% 方向
-define(DirEast, east).
-define(DirSouth, south).
-define(DirWest, west).
-define(DirNorth, north).

%% 标准命令
-define(ActionForward, forward).
-define(ActionBack, back).
-define(ActionTurnSouth, turnSouth).
-define(ActionTurnWest, turnWest).
-define(ActionTurnEast, turnEast).
-define(ActionTurnNorth, turnNorth).
-define(ActionAttack, attack).
-define(ActionWait, wait).

%% 记录时使用的行走命令
-define(ActionMove, move).

%% 战场日志文件名
-define(EbBattleLogFile, "warfield.txt").

%% 日志记录的消息命令字
-define(LogCmdAction, action).
-define(LogCmdStatus, status).
-define(LogCmdPlan, plan).
-define(LogCmdResult, result).

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
	


