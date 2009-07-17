-module(testAll).
-export([test/0]).

%% 测试入口
test() ->
	testBattleFieldCreate:test(),
	testErlBattleGetTime:test(),
	testErlBattleTakeAction:test().

