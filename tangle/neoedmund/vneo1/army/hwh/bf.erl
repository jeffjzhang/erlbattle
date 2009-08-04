-module(hwh.bf).
-compile(export_all).
-include("engine/schema.hrl").


get_soldier_by_position(Position) ->
	Pattern=#soldier{
				id='_',
				position=Position,
				hp='_',
				facing='_',
				action='_',
				act_effect_time = '_',
				act_sequence = '_'
			},
	
	case .ets:match_object(battle_field,Pattern) of
		[Soldier|_] ->
			Soldier;
		[]->
			none
	end.
