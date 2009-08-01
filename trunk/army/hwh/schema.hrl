


-record(phone,
	{
		channel,
		queue,
		info,
		side,
		grid
	}
).


-record(grid_info,
	{
		id,
		friend = [],
		enemy = []
	}
).