erlc -W erlbattle.erl battlefield.erl tools.erl worldclock.erl englandArmy.erl feardFarmers.erl 
erlc -W testAll.erl testWorldClockGetTime.erl testBattleFieldCreate.erl
erl -noshell -s testAll test -s init stop