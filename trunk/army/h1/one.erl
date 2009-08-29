-module(h1.one).
-compile(export_all).
-include("def.hrl").
-include("schema.hrl").


start_link(Master, ID, Phone) ->
	process_flag(trap_exit, true),
	put(master, Master),
	put(soldier_id, ID),
	Plans = .lists:map(fun(M) ->
			{ok, PID} = apply(M, start_link, [ID, Phone]),
			{PID, ?X_None_Score}
		end, 
		[h1.x_front, h1.x_near, h1.x_around]),
	loop(Master, Plans, none).


loop(Master, Plans, CurPlan) ->
	receive
		{'EXIT', Master, finish} ->
			.lists:foreach(fun({PID,_}) -> .gen_fsm:send_all_state_event(PID, stop) end, Plans);
		{set_score, PID, Score} ->
			{NewPlans, NewCurPlan} = change_plan(Plans, PID, Score, CurPlan),
			loop(Master, NewPlans, NewCurPlan);
		_ ->
			loop(Master, Plans, CurPlan)
	end.


change_plan(Plans, PID, Score, CurPlan) ->
	Plans1 = .lists:keystore(PID, 1, Plans, {PID, Score}),
	NewPlans = .lists:keysort(2, Plans1),
	NewCurPlan = notify_plan_change(CurPlan, .lists:last(NewPlans)),
	{NewPlans, NewCurPlan}.


notify_plan_change(CurPlan, {_PID, ?X_None_Score}) ->
	lost_control(CurPlan),
	none;
notify_plan_change(CurPlan, {PID, _}) ->
	lost_control(CurPlan),
	.gen_fsm:send_event(PID, set_control),
	PID.

lost_control(none) ->
	ok;
lost_control(PID) ->
	.gen_fsm:send_event(PID, lost_control).

