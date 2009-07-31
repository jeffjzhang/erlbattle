

-define(error1(Expr, Expected, Actual),
	io:format("~s is ~w instead of ~w at ~w:~w~n",
		  [??Expr, Actual, Expected, ?MODULE, ?LINE])).

-define(match(Expected, Expr),
        fun() ->
		Actual = (catch (Expr)),
		case Actual of
		    Expected ->
			{success, Actual};
		    _ ->
			?error1(Expr, Expected, Actual),
			erlang:error("match failed", Actual)
		end
	end()).


% 定义了一个打印调试信息的宏
-define(debug_print(Level, Str),
    fun() ->
        case Level of
            fatal   -> io:format("FATAL\t ~p:~p ~n\t~p~n", [?FILE, ?LINE, Str]);
            error   -> io:format("ERROR\t ~p:~p ~n\t~p~n", [?FILE, ?LINE, Str]);
            notice  -> io:format("NOTICE\t ~p:~p ~n\t~p~n",[?FILE, ?LINE, Str]);
            info    -> io:format("INFO\t ~p:~p ~n\t~p~n", [?FILE, ?LINE, Str]);
            true -> ok
        end
    end()).
    
