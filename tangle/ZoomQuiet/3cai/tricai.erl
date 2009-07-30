-module(tricai).
-include("schema.hrl").
%% try pre define soilder's nick name not work now
%%-include("tricai.hrl").
-export([run/3]).

%% @author Zoom.Quiet <Zoom.Quiet@gmail.com>
%% @version 0.0:Hanoi
%% @title ZQ's 3cai0 army,not realy power now...
%% @doc 3cai plan make built-in team to kill
%% but now,just usage "Towers of Hanoi" role
%% every 3 soldier as one team,follow loop steps
%% the last one just "skywalk"~flow the field running
%% @clean

%% only export fun
%% run(Channel, Side, Queue) -> none
run(Channel, Side, Queue) ->
	%% 可以不捕获，直接由父进程杀掉
	process_flag(trap_exit, true),
    io:format("TriCai v0.0:Hanoi now!	~n",[]),

    %% Army define :
    %% [a1,a2,a3,b1,b2,b3,c1,c2,c3,skywalker]-> id:
    %% [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10],

    io:format("send command: ~p  ~w ~w ~n",["forward",2,0]),
    Channel!{command,"forward",2,0},
    io:format("send command: ~w  ~w ~w ~n",["forward",5,0]),
    Channel!{command,"forward",5,0},
    io:format("send command: ~w  ~w ~w ~n",["forward",8,0]),
    Channel!{command,"forward",8,0},

    io:format("send command: ~w  ~w ~w ~n",["forward",10,0]),
    Channel!{command,"forward",10,0},

	loop(Channel, Side, Queue).

%% main loop
%% loop(Channel, Side, Queue) -> none
loop(Channel, Side, Queue) ->


	%Army = [1,2,3,4,5,6,7,8,9,10],
	%%lists:foreach(
        %%<fun(Soldier)>>,
		%%Army),

	%% 等待结束指令，其实这个程序不需要做任何善后，只是作为例子提供给大家模仿
	receive
		%% 结束战斗，可以做一些收尾工作后退出，或者什么都不做
		%% 这个消息不是必须处理的
		{'EXIT',_FROM, _Reason} ->  
			io:format("TriCai v0.0:Hanoi show over ~n",[]);

		_ ->
			loop(Channel, Side, Queue)

	after 100 -> 
			loop(Channel, Side, Queue)

	end.










