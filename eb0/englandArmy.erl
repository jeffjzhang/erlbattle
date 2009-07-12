-module(englandArmy).
-export([run/2]).

run(Channel, Side) ->
    
	%% 可以不捕获，直接由父进程杀掉
	process_flag(trap_exit, true),
	
	loop(Channel, Side).

loop(Channel, Side) ->
	
	Channel!{command,"forward",1,0},
	Channel!{command,"forward",2,0},
	Channel!{command,"forward",3,0},
	Channel!{command,"forward",4,0},
	Channel!{command,"forward",5,0},
	Channel!{command,"forward",6,0},
	Channel!{command,"forward",7,0},
	Channel!{command,"forward",8,0},
	Channel!{command,"forward",9,0},
	Channel!{command,"forward",10,0},
	
	receive
		%% 结束战斗，可以做一些收尾工作后退出，或者什么都不做
		%% 这个消息不是必须处理的
		{'EXIT',_FROM, finish} ->  
			io:format("england Army draw back ~n",[]);
					
		_ ->
			loop(Channel, Side)
			
	after 100 -> 
			loop(Channel, Side)
			
	end.
	