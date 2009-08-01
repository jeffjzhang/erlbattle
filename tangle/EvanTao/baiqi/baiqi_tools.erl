-module(baiqi_tools).
-include("schema.hrl").
-include("baiqi.hrl").

-compile(export_all).

%% 得到随机数
%% 范围是 1 ～ Value
get_random(Value) ->
    {A, B, C} = now(),
	random:seed(A, B, C),
    random:uniform(Value).

%% 自定义for循环
for(Max, Max, F) -> F(Max);
for(I, Max, F) -> F(I), for(I+1, Max, F).

%% 计算两个格子间的距离
get_distance({X1,Y1}, {X2,Y2}) ->
	abs(X1 - X2) + abs(Y1 - Y2).

%% 本队指令队列

%% 根据战士编号得到发给该战士的命令
get_soldier_cmd(SoldierId, QueueId) ->
    Pattern = #command{
                        soldier_id      = SoldierId,
                        name            = '_',
                        execute_time    = '_',
                        execute_seq     = '_',
                        seq_id          = '_'
                        },

    ets:select(QueueId, [{Pattern, [], ['$_']}]).


%% 战场信息表

%% 根据战队得到战士(0/n)
get_soldier_by_side(Side) ->
    Pattern = #soldier{
                        id              = {'_', Side},
                        position        = '_',
                        hp              = '_',
                        facing          = '_',
                        action          = '_',
                        act_effect_time = '_',
                        act_sequence    = '_'
                        },
                        
    ets:select(battle_field, [{Pattern, [], ['$_']}]).
    
%% 根据战士ID和战队得到战士(0/1)
get_soldier_by_id_side({SoldierId, Side}) ->
    get_soldier_by_id_side(SoldierId, Side).
    
get_soldier_by_id_side(SoldierId, Side) ->
    Pattern = #soldier{
                        id              = {SoldierId, Side},
                        position        = '_',
                        hp              = '_',
                        facing          = '_',
                        action          = '_',
                        act_effect_time = '_',
                        act_sequence    = '_'
                        },
                        
    case ets:select(battle_field, [{Pattern, [], ['$_']}]) of
        [Soldier] -> Soldier;
        [] -> none
    end.
        

%% 根据坐标点得到战士(0/1)
get_soldier_by_position(Position) ->
    Pattern = #soldier{
                        id              = '_',
                        position        = Position,
                        hp              = '_',
                        facing          = '_',
                        action          = '_',
                        act_effect_time = '_',
                        act_sequence    = '_'
                        },
                        
    case ets:select(battle_field, [{Pattern, [], ['$_']}]) of
        [Soldier] -> Soldier;
        [] -> none
    end.
