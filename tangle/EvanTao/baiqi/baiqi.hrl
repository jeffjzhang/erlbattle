%% 战士
%% {编号, 进程pid, 进程名, 属性 = {军衔, 职务, 小组, 上级}} {rank, post, group, superior}
-record(soldier_baiqi, {id, pid, proc_name, attr}).

%% 战士的任务
%% id
%% priority 优先级：1，2，3，。。。相同则随机
%% act 动作：move | attack
%% target 目标：soldier
-record(soldier_mission, {id, priority, act, target}).

%% 战士的命令队列
%% id
%% mission 任务ID
%% name 动作名称  = 标准命令
-record(soldier_cmd, {id, mission, name}).
