


-record(phone,
	{
		channel,
		queue,
		info,
		side,
		grid
	}
).

%% 战区信息
-record(grid_info,
	{
		id,
		friend = [],	%战区内友军
		enemy = []		%战区内敌军
	}
).