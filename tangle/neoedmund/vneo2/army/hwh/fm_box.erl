-module(hwh.fm_box).
-compile(export_all).



%%{ID, X, Y}
type(triangle2) ->
	.io:format("triangle2~n", []),
	[
		{1, 0, 2},
			{2, 1,3},
				{3, 2,4},
			{4, 1,5},
		{5, 0,6},
		{6, 0,7},
			{7, 1,8},
				{8, 2,9},
			{9, 1,10},
		{10, 0,11}
	];
type(double_w) ->
	.io:format("double_w~n", []),
	[
			{1, 1, 2},
		{2, 0, 3},
			{3, 1, 4},
		{4, 0, 5},
			{5, 1, 6},
			{6, 1, 7},
		{7, 0, 8},
			{8, 1, 9},
		{9, 0, 10},
			{10, 1, 11}
	];
type(crane) ->
	.io:format("crane~n", []),
	[
					{1, 3, 2},
				{2, 2, 3},
			{3, 1, 4},
		{4, 0, 5},
			{5, 1, 6},
			{6, 1, 7},
		{7, 0, 8},
			{8, 1, 9},
				{9, 2, 10},
					{10, 3, 11}
	];
type(random) ->
	L = [triangle2, double_w, crane],
	N = .random:uniform(length(L)),
	type(.lists:nth(N, L));
type(random2) ->
	L = [triangle2, double_w, crane, triangle2, double_w, crane],
	N = .random:uniform(length(L)),
	type(.lists:nth(N, L)).