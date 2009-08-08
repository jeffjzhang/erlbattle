-module(ai).
-include("schema.hrl").

-compile(export_all).

-define(MaxRow, 14).
-define(MaxCol, 14).

%% TODO
%% 生成棋盘，用来检测边界、敌人、地形成本等等
%% 不考虑ets,太慢。宁可传参数。:-P

%% 如果被多个进程共享，可以使用ets，然后更新到棋盘。
%% 尽量不要在算法里面操作ets。

start() ->
    Begin = {1, 3},
    End = {5, 0},
    
    {A1,A2,A3} = now(),
    io:format("StartTime = ~p~n", [{A1,A2,A3}]),
    
    %% 视线追逐算法
    %Path = build_path_to_target(Begin, End),
    
    %% A*算法
    Path = astar(Begin, End),
    
    {B1,B2,B3} = now(),
    io:format("StopTime = ~p~n", [{B1,B2,B3}]),
    io:format("From ~p to ~p~nPath=~p~nTime cost: ~pus~n", [Begin, End, Path, B3 - A3]),
    
    ok.

%% == Besenham算法 ==
build_path_to_target(Begin, End) when is_tuple(Begin) andalso is_tuple(End) ->
    {Row, Col} = Begin,
    {EndRow, EndCol} = End,
    
    if
        EndRow - Row < 0 -> StepRow = -1;
        true -> StepRow = 1
    end,
    
    if
        EndCol - Col < 0 -> StepCol = -1;
        true -> StepCol = 1
    end,
    
    DeltaRow = abs((EndRow - Row)*2),
    DeltaCol = abs((EndCol - Col)*2),
    
    if
        DeltaCol > DeltaRow ->
            Path = through_col(EndCol, Row, Col, StepRow, StepCol, 0, DeltaRow*2-DeltaCol, DeltaRow, DeltaCol);
        true ->
            Path = through_row(EndRow, Row, Col, StepRow, StepCol, 0, DeltaCol*2-DeltaRow, DeltaRow, DeltaCol)
    end,
    
    lists:reverse(Path).

through_col(EndCol, NextRow, NextCol, StepRow, StepCol, CurrentStep, Fraction, DeltaRow, DeltaCol) ->
    through_col([], EndCol-NextCol, EndCol, NextRow, NextCol, StepRow, StepCol, CurrentStep, Fraction, DeltaRow, DeltaCol).
    
through_col(Path, 0, _EndCol, _NextRow, _NextCol, _StepRow, _StepCol, _CurrentStep, _Fraction, _DeltaRow, _DeltaCol) ->
    Path;
through_col(Path, EndWhileCondition, EndCol, NextRow, NextCol, StepRow, StepCol, CurrentStep, Fraction, DeltaRow, DeltaCol) ->
    if
        Fraction >= 0 ->
            NextRow2 = NextRow + StepRow,
            NextCol2 = NextCol + StepCol,
            NextPath = {CurrentStep, {NextRow2, NextCol2}},
            Fraction2 = Fraction - DeltaCol + DeltaRow;
        true ->
            NextRow2 = NextRow,
            NextCol2 = NextCol + StepCol,
            NextPath = {CurrentStep, {NextRow2, NextCol2}},
            Fraction2 = Fraction + DeltaRow
    end,
    
    through_col([NextPath|Path], EndCol-NextCol2, EndCol, NextRow2, NextCol2, StepRow, StepCol, CurrentStep+1, Fraction2, DeltaRow, DeltaCol).

through_row(EndRow, NextRow, NextCol, StepRow, StepCol, CurrentStep, Fraction, DeltaRow, DeltaCol) ->
    through_row([], EndRow-NextRow, EndRow, NextRow, NextCol, StepRow, StepCol, CurrentStep, Fraction, DeltaRow, DeltaCol).
    
through_row(Path, 0, _EndRow, _NextRow, _NextCol, _StepRow, _StepCol, _CurrentStep, _Fraction, _DeltaRow, _DeltaCol) ->
    Path;
through_row(Path, EndWhileCondition, EndRow, NextRow, NextCol, StepRow, StepCol, CurrentStep, Fraction, DeltaRow, DeltaCol) ->
    if
        Fraction >= 0 ->
            NextRow2 = NextRow + StepRow,
            NextCol2 = NextCol + StepCol,
            NextPath = {CurrentStep, {NextRow2, NextCol2}},
            Fraction2 = Fraction - DeltaRow + DeltaCol;
        true ->
            NextRow2 = NextRow + StepRow,
            NextCol2 = NextCol,
            NextPath = {CurrentStep, {NextRow2, NextCol2}},
            Fraction2 = Fraction + DeltaCol
    end,
    
    through_row([NextPath|Path], EndRow-NextRow2, EndRow, NextRow2, NextCol2, StepRow, StepCol, CurrentStep+1, Fraction2, DeltaRow, DeltaCol).

%% == A*算法 ==

%% 节点的坐标={X, Y, 方向}，父节点坐标，成本
-record(tile, {pos, parent, cost}).

astar(PosStart, PosGoal) when is_tuple(PosStart) andalso is_tuple(PosGoal) ->
    TileStart = #tile{pos = PosStart, parent = null, cost = 0},
    TileGoal = #tile{pos = PosGoal, cost = 0},
    
    %% 先把起始节点放入 open list
    %% astar(open list ，结束节点，终结条件，closed list)
    astar([TileStart], TileGoal, PosStart==PosGoal, []).

astar(OpenList, TileGoal, true, ClosedList) ->
    %% 最简单的情况下，不用回溯。
    %lists:reverse(ClosedList);
    
    %% 否则，就要使用回溯到起点的方法找出路径。
    %% 回溯时，正好把list倒序，不需要reverse了。
    TilesList = [OpenList|ClosedList],
    Tile = lists:keyfind(TileGoal#tile.pos, 2, TilesList),
    get_path(Tile, TilesList, []);
astar([], _TileGoal, _EndCondition, _ClosedList) ->
    [];    
astar(OpenList, TileGoal, false, ClosedList) ->
    %% 当前节点 = open list 中成本最低的节点
    TileCurrent = get_lowest_cost_tile(OpenList),
    
    %% 把当前节点放进closed list
    OpenList2 = remove_lowest_cost_tile(OpenList, TileCurrent),
    ClosedList2 = [TileCurrent | ClosedList],
    
    %% 检查当前节点的每个相邻节点
    OpenList3 = check_around_tile(TileCurrent, OpenList2, ClosedList2, TileGoal),
    
    %% 当前节点 = 目标节点，则完成查找
    IsGoal = is_goal(TileCurrent, TileGoal),

    astar(OpenList3, TileGoal, IsGoal, ClosedList2).

%% 从目标开始，回溯到开始位置，生成路径。
get_path(false, _TilesList, Path) ->
    Path;
get_path(Tile, TilesList, Path) ->
    TileParent = lists:keyfind(Tile#tile.parent, 2, TilesList),
    get_path(TileParent, TilesList, [Tile|Path]).

%% 寻找open list中成本最低的节点，可能有多个
get_lowest_cost_tile([Tile|OpenList]) ->
    %% 随机选择
    TileMinCost = get_lowest_cost_tile(OpenList, Tile),
    TileMinCosts = lists:filter(
    fun(T) ->
        T#tile.cost == TileMinCost#tile.cost
    end,
    [Tile|OpenList]),
    %io:format("TileMinCosts=~p~n", [TileMinCosts]),
    lists:nth(srandom(length(TileMinCosts)), TileMinCosts).

    %% 默认选择
    %get_lowest_cost_tile(OpenList, Tile).

get_lowest_cost_tile([], Min) ->
    Min;
get_lowest_cost_tile([Tile|OpenList], Min) when Tile#tile.cost < Min#tile.cost ->
    get_lowest_cost_tile(OpenList, Tile);
get_lowest_cost_tile([Tile|OpenList], Min)  ->
    get_lowest_cost_tile(OpenList, Min).

%% 删除open list中成本最低的节点
remove_lowest_cost_tile(OpenList, TileCurrent) ->
    lists:delete(TileCurrent, OpenList).
    
%% 检查一个节点周围的其他节点
check_around_tile(Tile, OpenList, ClosedList, TileGoal) when is_record(Tile, tile) ->
    AroundTiles = get_around_tile(Tile),
    check_around_tiles(AroundTiles, OpenList, ClosedList, TileGoal).

%% 得到一个节点周围的其他节点
%% 标准砖块环境，是周围8个节点
%% 不过在EB中，改为直接相邻的4个。因为移动方向只能是直线。
%% 有优雅的实现麽？
get_around_tile(Tile) ->
    {X, Y} = Tile#tile.pos,
    
    if
        X+1 < 14 -> AroundTiles =[#tile{pos = {X+1, Y}, parent = Tile#tile.pos}];
        true -> AroundTiles = []
    end,
    if
        Y+1 < 14 -> AroundTiles2 = [#tile{pos = {X, Y+1}, parent = Tile#tile.pos}|AroundTiles];
        true -> AroundTiles2 = AroundTiles
    end,
    if
        X-1 > -1 -> AroundTiles3 = [#tile{pos = {X-1, Y}, parent = Tile#tile.pos}|AroundTiles2];
        true -> AroundTiles3 = AroundTiles2
    end,
    if
        Y-1 > -1 -> AroundTiles4 = [#tile{pos = {X, Y-1}, parent = Tile#tile.pos}|AroundTiles3];
        true -> AroundTiles4 = AroundTiles3
    end,
    AroundTiles4.
    
%% 检查一个节点周围的每个相邻节点
%% 每个相邻节点，如果不在open list不在closed list不是障碍物则放入open list并计算成本
check_around_tiles([], OpenList, _ClosedList, _TileGoal) ->
    OpenList;
check_around_tiles([Tile|AroundTiles], OpenList, ClosedList, TileGoal) ->
    IsInOpenList = lists:keymember(Tile#tile.pos, 2, OpenList),
    IsInClosedList = lists:keymember(Tile#tile.pos, 2, ClosedList),
    IsBarrier = tile_is_barrier(Tile),
    if
        not IsInOpenList
        and not IsInClosedList
        and not IsBarrier ->
            %% 当前节点是邻居的父节点
            %TileCurrent = Tile#tile.parent,
            TileCurrent = lists:keyfind(Tile#tile.parent, 2, OpenList),
            
            if
                TileCurrent == false ->
                    TileCurrent2  = lists:keyfind(Tile#tile.parent, 2, ClosedList);
                true ->
                    TileCurrent2 = TileCurrent
            end,
            
            %% 计算邻居节点的成本
            %% 开始节点有标志识别，因此不用单独传递进来
            Cost = calc_cost(Tile, TileGoal, TileCurrent2, OpenList),
            
            Tile2 = Tile#tile{cost = Cost},
            OpenList2 = [Tile2|OpenList];
        true ->
            OpenList2 = OpenList
    end,
    check_around_tiles(AroundTiles, OpenList2, ClosedList, TileGoal).

%% 检查当前节点是否是目标节点
%% 先检查坐标 TODO: 检查方向
is_goal(TileCurrent, TileGoal) ->
    TileCurrent#tile.pos == TileGoal#tile.pos.
    
%% 计算节点的成本
%% 移动到该节点的成本+该节点移动到目标的成本
%% TODO 移动时的成本要考虑到改变方向的花费。
calc_cost(TileNeighbor, TileGoal, TileCurrent, OpenList) ->
    g_n(TileNeighbor, TileCurrent, OpenList) + h_n(TileNeighbor, TileGoal).

%% 到邻居的成本为起始节点到当前节点的成本+当前节点移动到邻居的成本
g_n(TileNeighbor, TileCurrent, OpenList) ->
    SumCost = sum_movement_cost(TileCurrent, OpenList),

    {Xn, Yn} = TileNeighbor#tile.pos,
    {Xc, Yc} = TileCurrent#tile.pos,
    MovementCost = movement_cost({Xn, Yn}, {Xc, Yc}),
    SumCost + MovementCost.

%% 起始节点到当前节点的成本
sum_movement_cost(TileCurrent, OpenList) ->
    sum_movement_cost(TileCurrent, OpenList, 0).
    
sum_movement_cost(false, _OpenList, SumCost) ->
    SumCost;
sum_movement_cost(TileCurrent, OpenList, SumCost) ->
    PosCurrent = TileCurrent#tile.pos,
    TileParent = lists:keyfind(TileCurrent#tile.parent, 2, OpenList),
    if
        TileParent == false ->
            MovementCost = 0;
        true ->
            PosParent = TileParent#tile.pos,
            MovementCost = movement_cost(PosCurrent, PosParent)
    end,
    sum_movement_cost(TileParent, OpenList, SumCost+MovementCost).
    
%% 相邻的2个节点移动成本
%% TODO 考虑转身
movement_cost({Xo, Yo}, {Xt, Yt}) ->
    1.
    
%% 相邻的2个节点移动成本
%movement_cost({Xo, Yo, Dir}, {Xt, Yt}) ->
%    case is_same_dir({Xo, Yo, Dir}, {Xt, Yt}) of
%        true ->
%            2;
%            
%        false ->
%            4
%    end.

%% 相邻的2个格子的相对位置是否一样
is_same_dir({Xo, Yo, Dir}, {Xt, Yt}) ->
    case Dir of
        ?DirEast ->
            none;
            
        ?DirSouth ->
            none;
            
        ?DirWest ->
            none;
            
        ?DirNorth ->
            none
            
    end,
    true.

%% 启发式函数，用来估算当前节点到目标节点间的距离
h_n(TileNeighbor, TileGoal) ->
    {Xn, Yn} = TileNeighbor#tile.pos,
    {Xg, Yg} = TileGoal#tile.pos,
    heuristic_ManhattanDistance({Xn, Yn}, {Xg, Yg}).
    
%% 启发式函数-曼哈顿距离
heuristic_ManhattanDistance({Xo, Yo}, {Xt, Yt}) ->
    abs(Xo-Xt) + abs(Yo-Yt).

%% 判断节点是否是障碍物
tile_is_barrier(Tile) ->
    false.

%% 随机数
srandom(Value) ->
    {A, B, C} = now(),
	random:seed(A, B, C),
    random:uniform(Value).












