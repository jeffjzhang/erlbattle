-module(h1.x_near).
-behaviour(gen_fsm).
-compile(export_all).
-export([init/1, handle_event/3, terminate/3]).
-include("schema.hrl").
-include("def.hrl").


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
	Soldiers = get_near(ID, Phone),
	NewData = notify_detect_result(Soldiers, Data),
	h1.util:next_detect_state(Soldiers, state_detecting, {ID, Phone, NewData});
state_detecting(set_control, StateData) ->
	{next_state, state_fighting, StateData, 1}.


get_near(ID, Phone) ->
	h1.util:get_enemy(ID, Phone, 
		fun(_) -> [{1,0}, {-1,0}, {0,1}, {0,-1}] end,
		h1.util:friend_filter(Phone),
		fun(Soldier, E1, E2) ->
			E1_score = h1.util:near_enemy_score(Soldier, E1),
			E2_score = h1.util:near_enemy_score(Soldier, E2),
			E1_score >= E2_score
		end).


notify_detect_result(Soldiers, Data) ->
	OldScore = Data#data.last_score,
	NewScore = h1.util:notify_detect_result(Soldiers, OldScore, ?X_Near_Score),
	Data#data{ last_score = NewScore }.


state_fighting(timeout, {ID, Phone, Data}) ->
	Soldiers = get_near(ID, Phone),
	attack_near(ID, Soldiers, Phone),
	NewData = notify_detect_result(Soldiers, Data),
	h1.util:next_detect_state(Soldiers, state_fighting, {ID, Phone, NewData});
state_fighting(lost_control, StateData) ->
	{next_state, state_detecting, StateData, 1}.


attack_near(_ID, idead, _Phone) ->
	noaction;
attack_near(_ID, none, _Phone) ->
	noaction;
attack_near(ID, {Soldier, Enemy}, Phone) ->
	Dir = h1.util:which_dir(Soldier, Enemy),
	attack_on_dir(ID, Soldier, Dir, Phone).

attack_on_dir(ID, #soldier{ facing = Dir}, Dir, Phone) ->
	Channel = Phone#phone.channel,
	Channel ! {command, ?ActionAttack, ID, 0, 0};
attack_on_dir(ID, Soldier, Dir, Phone) ->
	Action = h1.util:turn_action(Dir),
	Channel = Phone#phone.channel,
	if
		Action =:= Soldier#soldier.action ->
			Channel ! {command, ?ActionAttack, ID, 0, 0};
		true ->
			Channel ! {command, Action, ID, 0, 0}
	end.


handle_event(stop, _StateName, StateData) ->
	{stop, shutdown, StateData}.


terminate(_, _, _) -> ok.
