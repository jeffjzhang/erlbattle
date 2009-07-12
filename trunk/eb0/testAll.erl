-module(testAll).
-export([test/0]).

test() ->
	testBattleFieldCreate:test(),
	testErlBattleGetTime:test(),
	testErlBattleTakeAction:test().

