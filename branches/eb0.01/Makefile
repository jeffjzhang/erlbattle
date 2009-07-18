.SUFFIXES: .erl .beam
 
.erl.beam:
	erlc -W $<
 
ERL = erl -boot start_clean
 
MODS = erlbattle englandArmy feardFarmers
 
all: compile
	${ERL} -noshell -s erlbattle start 
 
compile: ${MODS:%=%.beam}
 
clean: 
	rm -rf *.beam
