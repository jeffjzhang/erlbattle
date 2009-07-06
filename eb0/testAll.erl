-module(testAll).
-export([test/0]).

test() ->
	testBattleFieldCreate:test(),
	testWorldClockGetTime:test(),
	testErlBattleTakeAction:test().

