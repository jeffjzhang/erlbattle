-module(h1.x_around).
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
	Soldiers = get_around(ID, Phone),
	NewData = notify_detect_result(Soldiers, Data),
	h1.util:next_detect_state(Soldiers, state_detecting, {ID, Phone, NewData});
state_detecting(set_control, StateData) ->
	{next_state, state_fighting, StateData, 1}.


get_around(ID, Phone) ->
	h1.util:get_enemy(ID, Phone, 
		fun(_) -> [{1,1}, {1,-1}, {-1,1}, {-1,-1}] end,
		h1.util:friend_filter(Phone),
		fun(_Soldier, E1, E2) ->
				{ID1, _Side} = E1#soldier.id,
				{ID2, _Side} = E2#soldier.id,
				ID1 =< ID2
		end).


notify_detect_result(Soldiers, Data) ->
	OldScore = Data#data.last_score,
	NewScore = h1.util:notify_detect_result(Soldiers, OldScore, ?X_Around_Score),
	Data#data{ last_score = NewScore }.


state_fighting(timeout, {ID, Phone, Data}) ->
	Soldiers = get_around(ID, Phone),
	attack_around(ID, Soldiers, Phone),
	NewData = notify_detect_result(Soldiers, Data),
	h1.util:next_detect_state(Soldiers, state_fighting, {ID, Phone, NewData});
state_fighting(lost_control, StateData) ->
	{next_state, state_detecting, StateData, 1}.


attack_around(_ID, idead, _Phone) ->
	noaction;
attack_around(_ID, none, _Phone) ->
	noaction;
attack_around(ID, {Soldier, Enemy}, Phone) ->
	EnemyPresume = presume(Enemy),
	attack(ID, Soldier, EnemyPresume, Phone).

attack(ID, Soldier, {move, EnemyPosition}, Phone) ->
	Dir = h1.util:which_dir(Soldier#soldier.position, EnemyPosition),
	turn_to_direction(ID, Phone, Soldier, Dir);
attack(ID, Soldier, {nomove, EnemyPosition}, Phone) ->
	Dir = h1.util:which_dir(Soldier#soldier.position, EnemyPosition),
	turn_to_direction(ID, Phone, Soldier, Dir).

turn_to_direction(_ID, _Phone, #soldier{ facing = Dir }, Dir) ->
	ok;
turn_to_direction(ID, Phone, _Soldier, Dir) ->
	Action = h1.util:turn_action(Dir),
	Channel = Phone#phone.channel,
	Channel ! {command, Action, ID, 0, 0}.

presume(#soldier{ action = ?ActionForward, facing = Facing, position = {X, Y} }) ->
	{OX, OY} = h1.util:forward(Facing, 1),
	{move, {X+OX, Y+OY} };
presume(Soldier) ->
	{nomove, Soldier#soldier.position}.

		
handle_event(stop, _StateName, StateData) ->
	{stop, shutdown, StateData}.


terminate(_, _, _) -> ok.
