-module(englandArmy).
-export([run/2]).

run(Channel, Side) ->
    
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
	
	tools:sleep(100),

	%% 结束战斗，可以做一些收尾工作后退出，或者什么都不做
	%% 这个消息不是必须处理的
	receive
		{'EXIT',_FROM, finish} ->  
			true;
		
		_ ->
			run(Channel, Side)
			
	after 1 -> 
			run(Channel, Side)
	end.
	