.SUFFIXES: .erl .beam
 
.erl.beam:
	erlc -W $<
 
ERL = erl -boot start_clean
 
MODS = erlbattle englandArmy feardFarmers battlefield tools.erl worldclock.erl  
 
all: compile
	${ERL} -noshell -s erlbattle start 
 
compile: ${MODS:%=%.beam}
 
clean: 
	rm -rf *.beam erl_crash.dump
