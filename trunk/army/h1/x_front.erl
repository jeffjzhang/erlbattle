-module(h1.x_front).
-behaviour(gen_fsm).
-compile(export_all).
-include("schema.hrl").
-include("def.hrl").
-export([init/1, handle_event/3, terminate/3]).


-record(data,
	{
		last_score = -1
	}
).


start_link(ID, Phone) ->
	.gen_fsm:start_link(?MODULE, {self(), ID, Phone}, []).


init({Master, ID, Phone}) ->
	put(master, Master),
	{ok, state_detecting, {ID, Phone, #data{}}, 1}.


state_detecting(timeout, {ID, Phone, Data}) ->
	Soldiers = get_front(ID, Phone),
	NewData = notify_detect_result(Soldiers, Data),
	h1.util:next_detect_state(Soldiers, state_detecting, {ID, Phone, NewData});
state_detecting(set_control, StateData) ->
	{next_state, state_fighting, StateData, 1}.


get_front(ID, Phone) ->
	h1.util:get_enemy(ID, Phone,
		fun(#soldier{facing = Facing}) ->
				[h1.util:forward(Facing, 1), h1.util:forward(Facing, 2)]
		end,
		h1.util:friend_filter(Phone),
		fun(Soldier, E1, E2) ->
			Dist1 = h1.util:dist(Soldier, E1),
			Dist2 = h1.util:dist(Soldier, E2),
			Dist1 =< Dist2
		end).


notify_detect_result(Soldiers, Data) ->
	OldScore = Data#data.last_score,
	NewScore = h1.util:notify_detect_result(Soldiers, OldScore, ?X_Front_Score),
	Data#data{ last_score = NewScore }.


state_fighting(timeout, {ID, Phone, Data}) ->
	Soldiers = get_front(ID, Phone),
	attack_front(ID, Soldiers, Phone),
	NewData = notify_detect_result(Soldiers, Data),
	h1.util:next_detect_state(Soldiers, state_fighting, {ID, Phone, NewData});
state_fighting(lost_control, StateData) ->
	{next_state, state_detecting, StateData, 1}.


attack_front(_ID, idead, _Phone) ->
	noaction;
attack_front(_ID, none, _Phone) ->
	noaction;
attack_front(ID, _Soldiers, #phone{channel = Channel}) ->
	Channel ! {command, ?ActionAttack, ID, 0, 0}.


handle_event(stop, _StateName, StateData) ->
	{stop, shutdown, StateData}.


terminate(_, _, _) -> ok.
