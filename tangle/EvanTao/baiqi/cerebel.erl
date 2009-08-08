%% 小脑，发出命令
%% 负责将组合命令分解成标准命令
%% 前进 forward, 后退 back,
%% 转向 turnSouth, turnNorth, turnWest,turnEast
%% 攻击 attack
%% 原地待命 wait

-module(cerebel).
-include("schema.hrl").
-include("baiqi.hrl").

-export([start/2]).

start(Soldier, ChannelProc) ->
    process_flag(trap_exit, true),

    %% 战士的目标
    Mission_queue = ets:new(soldier_mission_queue, [ordered_set, private, {keypos, #soldier_mission.id}]),
    %% 战士的行动消息队列
    Cmd_queue = ets:new(soldier_cmd_queue, [ordered_set, private, {keypos, #soldier_cmd.id}]),

    loop(Soldier, ChannelProc, Mission_queue, Cmd_queue).

loop(Soldier, ChannelProc, Mission_queue, Cmd_queue) ->
    receive
        'ActionDone' -> %% 发出下一个命令
            %% 如果目标未完成，则执行，否则等待
            Goal = length(ets:tab2list(Mission_queue)),
            if
                Goal > 0 ->
                    %% 检查计划
                    revise_plan(Soldier, Mission_queue, Cmd_queue),
            
                    %% 执行计划
                    Cmd = get_next_cmd(Mission_queue, Cmd_queue),
                    {SoldierId, _Side} = Soldier#soldier.id,
                    %io:format("==== cerebel[~p] sent a command[~p]~n", [SoldierId, Cmd]),
                    ChannelProc ! {command, Cmd, SoldierId, 0, get_random_seq()};

                true ->
                    none
            end,

            loop(Soldier, ChannelProc, Mission_queue, Cmd_queue);

        {'Attack', SoldierEnemy, CmdSender} ->
            %% 分析命令，制定计划
            parse_attack(Soldier, SoldierEnemy, Mission_queue, Cmd_queue),
            %% 检查计划
            %revise_plan(Soldier, Mission_queue, Cmd_queue),
            %% 执行计划
            self() ! 'ActionDone',
            
            loop(Soldier, ChannelProc, Mission_queue, Cmd_queue);

        {'EXIT', _From, _Reason} ->
            %io:format("   = cerebel[~p] exited~n", [SoldierId]),
            {SoldierId, _Side} = Soldier#soldier.id;

        _Other ->
            %revise_plan(Soldier, Mission_queue, Cmd_queue),
            loop(Soldier, ChannelProc, Mission_queue, Cmd_queue)

    after 10 ->
        %revise_plan(Soldier, Mission_queue, Cmd_queue),
        loop(Soldier, ChannelProc, Mission_queue, Cmd_queue)
    end.

%% 随机指令
get_random_cmd() ->
    case baiqi_tools:get_random(8) of
        1 -> "forward";
        2 -> "back";
        3 -> "turnSouth";
        4 -> "turnNorth";
        5 -> "turnWest";
        6 -> "turnEast";
        7 -> "attack";
        8 -> "wait"
    end.

%% 随机次序
get_random_seq() ->
    baiqi_tools:get_random(10).

%% 产生行动计划
%% 将一系列指令放入队列中
parse_attack(SoldierWe, SoldierEnemy, Mission_queue, Cmd_queue) ->
    %io:format("SoldierId=~p, Side=~p~n", [Soldier]),
    %% 我方战士信息
    {SoldierId_we, Side_we} = SoldierWe#soldier.id,
    Soldier_we = baiqi_tools:get_soldier_by_id_side(SoldierId_we, Side_we),

    %% 设定任务目标
    Soldier_mission = #soldier_mission{
                                id          = 0,
                                priority    = 1,
                                act         = "attack",
                                target      = SoldierEnemy
                            },
    ets:insert(Mission_queue, Soldier_mission),

    ets:delete_all_objects(Cmd_queue),
    gen_plan(Soldier_we, SoldierEnemy, Cmd_queue).

gen_plan(SoldierWe, SoldierEnemy, Cmd_queue) ->
    if
        %% 我方战士牺牲
        SoldierWe == none ->
            none;

        %% 我方战士存活
        true ->
                %io:format("Soldier:[~p]~n", [Soldier]),
            %% 我方战士位置
            {Xwe, Ywe} = SoldierWe#soldier.position,

            %% 敌方战士信息
            Soldier_enemy = baiqi_tools:get_soldier_by_id_side(SoldierEnemy#soldier.id),

            if
                %% 敌人已清除，自行寻找最近的敌人或与同伴夹击
                Soldier_enemy == none ->
                    none;

                %% 敌人存活，咩他
                true ->

                    %% 敌方背后位置
                    {Xe, Ye} = Soldier_enemy#soldier.position,
                    Faced_enemy = Soldier_enemy#soldier.facing,
                    {Xenemy, Yenemy} = get_behind_pos(Faced_enemy, Xe, Ye),
                    %{Faced_enemy, Xenemy, Yenemy} = {"north", 11, 4},

                    %% 路线都是直线，加转弯
                    MaxX = abs(Xwe-Xenemy),
                    MaxY = abs(Ywe-Yenemy),

                    {ActX, ActY} = confirm_direction({SoldierWe#soldier.facing, Xwe, Ywe}, {Faced_enemy, Xenemy, Yenemy}),

                    if
                        ActX == "equal" ->
                            none;

                        true ->
                            Soldier_cmd_X = #soldier_cmd{
                                id          = 0,
                                mission     = 0,
                                name        = ActX
                            },
                            ets:insert(Cmd_queue, Soldier_cmd_X)
                    end,

                    %% 直走
                    Lxid = lists:seq(1, MaxX),

                    lists:foreach(
                        fun(Id) ->
                            Soldier_cmd = #soldier_cmd{
                                id          = Id,
                                mission     = 0,
                                name        = "forward"
                            },
                            ets:insert(Cmd_queue, Soldier_cmd)
                        end,
                        Lxid),

                    %% 转弯
                    if
                        ActY == "equal" ->
                            none;

                        true ->
                            Soldier_cmd_Y = #soldier_cmd{
                                id          = MaxX+1,
                                mission     = 0,
                                name        = ActY
                            },
                            ets:insert(Cmd_queue, Soldier_cmd_Y)
                    end,

                    %% 直走
                    Lyid = lists:seq(MaxX+1+1, MaxX+1+MaxY),
                    lists:foreach(
                        fun(Id) ->
                            Soldier_cmd = #soldier_cmd{
                                id          = Id,
                                mission     = 0,
                                name        = "forward"
                            },
                            ets:insert(Cmd_queue, Soldier_cmd)
                        end,
                        Lyid)
                    
                    %% 达到目的地后再判断是否要转向以正对敌人

            end
    end.

%% 从一点移动到另外一点
%% 返回标准命令序列[forward, turEast, ...]
move_from_to({Facing, Xo, Yo}, {Faced, Xt, Yt}) ->
    {ActX, ActY} = confirm_direction({Facing, Xo, Yo}, {Faced, Xt, Yt}),
    none.
    
%% 攻击
attack_to({Facing, Xo, Yo}, {Faced, Xt, Yt}) ->
    {ActX, ActY} = confirm_direction({Facing, Xo, Yo}, {Faced, Xt, Yt}),
    
    if
        ActX == "equal" -> none;
        true -> none
    end,
    
    none.


gen_forward_cmd_from_list([H | T]) ->
    gen_forward_cmd_from_list([H | T], []).

gen_forward_cmd_from_list([H | T], Lxcmd) ->
    Cmd = {H, "forward"},
    gen_forward_cmd_from_list(T, [Cmd|Lxcmd]);
gen_forward_cmd_from_list([], Lxcmd) ->
    Lxcmd.

move_to_position(Soldier, Position) ->
    none.

attack_soldier(Soldier, EnemySoldierId) ->
    none.

%% 确定战士和目标之间的相对位置
%% 确定战士行进的方向
%% Origin = Target = position = {x, y}
confirm_direction({Facing, Xo, Yo}, {Faced, Xt, Yt}) ->
    if
        Xo < Xt  ->
            if
                Facing == "east" -> ActX = "equal";
                true -> ActX = "turnEast"
            end;

        Xo == Xt -> ActX = "equal";

        Xo > Xt  ->
            if
                Facing == "west" -> ActX = "equal";
                true -> ActX = "turnWest"
            end
    end,

    if
        Yo < Yt  ->
            if
                Facing == "north" -> ActY = "equal";
                true -> ActY = "turnNorth"
            end;

        Yo == Yt -> ActY = "equal";

        Yo > Yt  ->
            if
                Facing == "south" -> ActY = "equal";
                true -> ActY = "turnSouth"
            end
    end,
    {ActX, ActY}.

%% 取一条命令执行
%% 如果队列中没有命令则默认为wait
get_next_cmd(Mission_queue, Cmd_queue) ->
    Key = ets:first(Cmd_queue),
    %io:format("Key=~p~n", [Key]),
    %ets:select_delete(soldier_cmd, {Key, '_Name'}),
    %io:format(ets:i(Cmd_queue)),
    if
        Key == '$end_of_table' ->
            Cmd = "wait";
        true ->
            Soldier_cmd = lists:nth(1, ets:select(Cmd_queue, [{#soldier_cmd{id = Key, mission = '_', name = '_'}, [], ['$_']}])),
            Cmd = Soldier_cmd#soldier_cmd.name,
            
            ets:delete(Cmd_queue, Key),
            %% 检查下一条记录，如果么有了，这是最后一条记录，说明mission的任务完成了。从任务表中删除。
            case ets:next(Cmd_queue, Key) of
                '$end_of_table' ->
                    ets:delete(Mission_queue, Soldier_cmd#soldier_cmd.mission);

                Key_next ->
                    %io:format("Key_next=~p~n", [Key_next]),
                    none
            end
    end,
    %io:format("Cmd=~p~n", [Cmd]),
    %io:format("Key=~p, Cmd=~p~n", [Key, Cmd]),
    Cmd.

%% 查看下一条命令
view_next_cmd(Mission_queue, Cmd_queue) ->
    Key = ets:first(Cmd_queue),
    if
        Key == '$end_of_table' ->
            Cmd = "wait";
        true ->
            Soldier_cmd = lists:nth(1, ets:select(Cmd_queue, [{#soldier_cmd{id = Key, mission = '_', name = '_'}, [], ['$_']}])),
            Cmd = Soldier_cmd#soldier_cmd.name
    end,
    Cmd.

%% 检查一条命令是否能执行成功
%% 转向肯定成功
%% 攻击、前进、后退需要考虑目标位置是否有人，或者是否要和别人争抢同一个位置
check_cmd(Soldier, Cmd, Mission_queue, Cmd_queue) ->
    %% 得到战士当前位置、朝向、生效时间
    Soldier_we = baiqi_tools:get_soldier_by_id_side(Soldier#soldier.id),
    {Facing, {Xo, Yo}} = {Soldier_we#soldier.facing, Soldier_we#soldier.position},
    
    %io:format("action=~p, act_effect_time=~p~n", [Soldier_we#soldier.action, Soldier_we#soldier.act_effect_time]),
    
    %Cmd_in_queue = baiqi_tools:get_soldier_cmd(SoldierId, ),
    
    %% 得到前面的格子
    {Xt, Yt} = get_future_pos(Cmd, Facing, {Xo, Yo}),
    
    %% 跟前的格子是否有敌人
    Soldier_enemy = baiqi_tools:get_soldier_by_position({Xt, Yt}),
    if
        %% 前面没人，预测
        Soldier_enemy == none ->
            %% 判断目标格子是否会有障碍
            
            %% 得到{Xo, Yo}目标{Xt, Yt}周围的其他3个格子
            L_round_pos = get_around_pos({Xo, Yo}, {Xt, Yt}),
            %io:format("ori=~p, des=~p~nround=~p~n", [{Xo, Yo}, {Xt, Yt}, L_round_pos]),
            %io:format("ori=~p, des=~p, penemy=~p~n", [{Xo, Yo}, {Xt, Yt}]),
            %io:format("round = ~p~n", [length(L_round_pos)]),

            L_future_facing = check_future_pos({Xt, Yt}, Soldier_we#soldier.act_effect_time, L_round_pos);
            %io:format("L_future_facing=~p~n", [L_future_facing]),
            
        true ->
            FacingEnemy = Soldier_enemy#soldier.facing,
            %L_future_facing = [Soldier_enemy#soldier.facing]
            L_future_facing = [FacingEnemy]
    end, 
    
    %% 如果目标格有人，且不是面对面，就攻击，否则绕路
    %% 如果没人，就前进(攻击则改成重新寻找目标)
    EnemyCount = length(L_future_facing),
    if 
        %% 有一个人则攻击？
        EnemyCount == 1 ->
            [FacingFuture] = L_future_facing,
            Is_face2face = is_face2face(FacingFuture, Facing),
            if
                %% 面对面就绕路
                Is_face2face == true -> Ret = 'detour';
                %% 否则攻击
                true -> Ret = 'attack'
            end;

        %% 没人或者多人就走人
        true ->
            if
                Cmd == "attack" -> Ret = 'search';
                true -> Ret = 'none'
            end
    end,
    Ret.

is_face2face(Face1, Face2) ->
    {Face1, Face2} == {"east", "west"} orelse
    {Face1, Face2} == {"west", "east"} orelse
    {Face1, Face2} == {"south", "north"} orelse
    {Face1, Face2} == {"north", "south"}.

%% 得到由{Xo, Yo}出发的下一个格子位置
get_future_pos(Cmd, Facing, {Xo, Yo}) ->
    case Cmd of
        "back"      ->
            {Xt, Yt} = get_behind_pos(Facing, Xo, Yo);
        "attack"    ->
            {Xt, Yt} = get_ahead_pos(Facing, Xo, Yo);
        "forward"   ->
            {Xt, Yt} = get_ahead_pos(Facing, Xo, Yo);
        _Else       ->
            {Xt, Yt} = {Xo, Yo}
    end,
    {Xt, Yt}.
    
%% 检查每个格子的预期情况
%% 在T时间时是否有人到达/离开、朝向等
check_future_pos({Xt, Yt}, TimeFuture, L_round_pos) ->
    %io:format("L_round_pos:~p~n", [L_round_pos]),
    check_future_pos({Xt, Yt}, TimeFuture, L_round_pos, []).
    
check_future_pos({_X, _Y}, _TimeFuture, [], Result) ->
    Result;
check_future_pos({Xt, Yt}, TimeFuture, [H|T], Result) ->
    %% 目标格有人？
    %io:format("H=~p~n", [H]),
    Soldier = baiqi_tools:get_soldier_by_position(H),
    
    if 
        Soldier == none ->
            Ret = false;
        
        %% 有人就检查他的目标格是否就是我们要去的格子
        %% 生效时间要比我们的时间早
        true ->
            %io:format("des=~p, penemy=~p~n", [{Xt, Yt}, Soldier#soldier.position]),
            if
                TimeFuture =< Soldier#soldier.act_effect_time ->
                    {X, Y} = get_future_pos(Soldier#soldier.action,
                                            Soldier#soldier.facing,
                                            Soldier#soldier.position),
                    if
                        {X, Y} == {Xt, Yt} -> Ret = true;
                        true -> Ret = false
                    end;
                    
                true ->
                    Ret = false
            end
    end,
    
    if
        Ret == true -> check_future_pos({Xt, Yt}, TimeFuture, T, [Soldier#soldier.facing|Result]);
        Ret == false -> check_future_pos({Xt, Yt}, TimeFuture, T, Result)
    end.
    

%% 检查格子是否有人
%% 有人 true
%% 无人 false
pos_is_used({X, Y}) ->
    Soldier = baiqi_tools:get_soldier_by_position({X, Y}),

    Soldier /= none.

%% 得到{Xo, Yo}目标{Xt, Yt}周围的其他3个格子
get_around_pos({Xo, Yo}, {Xt, Yt}) ->
    East    = {Xt+1, Yt},
    North   = {Xt, Yt-1},
    West    = {Xt-1, Yt},
    South   = {Xt, Yt+1},
    L = [East, North, West, South],
    %io:format("round=~p~n", [L]),
    lists:filter(
		fun(Pos) ->
			{Xo, Yo} /= Pos
		end,
		L).

%% 得到前面的一个格子位置
get_ahead_pos(Facing, X, Y) ->
    case Facing of
        "east"  -> {X+1, Y};
        "north" -> {X, Y-1};
        "west"  -> {X-1, Y};
        "south" -> {X, Y+1};
        _Else   -> {X, Y}
    end.

%% 得到后面的一个格子位置
get_behind_pos(Facing, X, Y) ->
    case Facing of
        "east"  ->
            if
                X > 0   -> {X-1, Y};
                true    -> {X, Y}
            end;
        "west"  ->
            if
                X < 14  -> {X+1, Y};
                true    -> {X, Y}
            end;

        "south" ->
            if
                Y < 14  -> {X, Y+1};
                true    -> {X, Y}
            end;

        "north" ->
            if
                Y > 0   -> {X, Y-1};
                true    -> {X, Y}
            end
    end.

%% 检查计划执行情况，随时修订计划
revise_plan(Soldier, Mission_queue, Cmd_queue) ->
    %% 得到战士当前位置
    Soldier_we = baiqi_tools:get_soldier_by_id_side(Soldier#soldier.id),
    
    %% 得到目标当前位置
    Key = ets:first(Mission_queue),
    if
        Key == '$end_of_table' ->
            Soldier_enemy = Soldier_we;
        true ->
            Soldier_info = lists:nth(1, ets:select(Mission_queue, [{#soldier_mission{id = Key, priority='_', act='_', target='_'}, [], ['$_']}])),
            Soldier_enemy = Soldier_info#soldier_mission.target
    end,

    %% 判断队列中将要执行的命令是否能成功，否则换个路线
    Cmd_we = view_next_cmd(Mission_queue, Cmd_queue),
    
    case check_cmd(Soldier, Cmd_we, Mission_queue, Cmd_queue) of
        %% 单人面对面或者多人，就绕路
        'detour' ->
            modify_soldier_cmd_queue("attack", Cmd_queue);
            %Cmd_next = view_next_cmd(Mission_queue, Cmd_queue),
            %io:format("Cmd_next=~p~n", [Cmd_next]);
            
        %% 单人但是不是面对面，则攻击
        'attack' ->
            modify_soldier_cmd_queue("attack", Cmd_queue);
            %Cmd_next = view_next_cmd(Mission_queue, Cmd_queue),
            %io:format("Cmd_next=~p~n", [Cmd_next]);
            
        %% 攻击时没人，则搜索敌人
        'search' ->
            re_gen_plan(Soldier_we, Soldier_enemy, Cmd_queue);
            
        %% 没人继续原来
        'none' ->
            re_gen_plan(Soldier_we, Soldier_enemy, Cmd_queue)
    end.
    
%% 重新设定路线
re_gen_plan(Soldier, Soldier_enemy, Cmd_queue) ->
    ets:delete_all_objects(Cmd_queue),
    gen_plan(Soldier, Soldier_enemy, Cmd_queue).
    
%% 修改命令队列的最先一条
modify_soldier_cmd_queue(Cmd, Cmd_queue) ->
    Key = ets:first(Cmd_queue),
    %io:format("Key = ~p, Cmd = ~p~n", [Key, Cmd]),
    if
        Key == '$end_of_table' ->
            Soldier_cmd = #soldier_cmd{
                                id          = 0,
                                mission     = 0,
                                name        = Cmd
                            },
            ets:insert(Cmd_queue, Soldier_cmd);
            
        true ->
            ets:update_element(Cmd_queue, Key, [{4, Cmd}])
            %K = ets:first(Cmd_queue),
            %C = lists:nth(1, ets:select(Cmd_queue, [{#soldier_cmd{id = Key, mission='_', name='_'}, [], ['$_']}])),
            %io:format("Key2 = ~p, Cmd2 = ~p~n", [K, C])
    end.


