-module(testEbLogger).
-export([test/0]).
-include("test.hrl").
-include("schema.hrl").
-include("ebLogger.hrl").


test() ->
	ebLogger:start(),
	?info("This is a info log message"),
	?info2("This is a info log : ~p", ["hello"]),
	?warn("This is a info log message"),
	?warn2("This is a info log : ~p", ["hello"]),
	?error("This is a info log message"),
	?error2("This is a info log : ~p", ["hello"]),
	?fatal("This is a info log message"),
	?fatal2("This is a info log : ~p", ["hello"]),
	?debug("This is a info log message"),
	?debug2("This is a info log : ~p", ["hello"]),
	ebLogger:stop().


