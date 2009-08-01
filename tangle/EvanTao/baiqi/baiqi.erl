%%% 指挥官进程。
%%% 生成各个战士进程，并进行战略层次的指挥。
%%% 如分成2队包抄、1队进攻1队支援等命令

-module(baiqi).
-include("schema.hrl").
-include("baiqi.hrl").

%% 外部调用
-export([run/3]).

run(ChannelProc, Side, CmdQueue) ->
    process_flag(trap_exit, true),
    
    Army = ?PreDef_army,
    
    NewArmy = create_soldier(ChannelProc, Side, CmdQueue, Army),
    CorporalProc = spawn_link(corporal, start, [self(), Side, NewArmy]),
    
    %% 自由攻击
    CorporalProc ! {'AttackAuto', self()},
    
    loop(CorporalProc).

%% 将每个战士编号生产一个战士进程，并记录进程号，返回存储该信息的新列表
create_soldier(ChannelProc, Side, CmdQueue, Army) ->
    create_soldier(ChannelProc, Side, CmdQueue, Army, []).

create_soldier(ChannelProc, Side, CmdQueue, [SoldierId|RestSoldierIdes], NewArmy) ->
    Soldier = baiqi_tools:get_soldier_by_id_side(SoldierId, Side),
    Soldier_baiqi = #soldier_baiqi{id=SoldierId, pid=spawn_link(soldier, start, [Soldier, ChannelProc, CmdQueue])},
    create_soldier(ChannelProc, Side, CmdQueue, RestSoldierIdes, [Soldier_baiqi|NewArmy]);
create_soldier(_ChannelProc, _Side, _CmdQueue, [], NewArmy) ->
    NewArmy.

loop(CorporalProc) ->
    receive
        {'EXIT', _From, _Reason} ->
            %if
            %    From == CorporalProc -> io:format("==== baiqi army go home~~~~~~~n");
            %    true -> none%loop(CorporalProc)
            %end,
            io:format("==== baiqi army go home~~~~~~~n");
            
        _Other ->
            loop(CorporalProc)
    
        after 1000*3600 ->
            loop(CorporalProc)
    end.
