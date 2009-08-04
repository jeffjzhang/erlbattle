#!/bin/python
def run():
	army=["englandArmy","feardFarmers","hwh.triple","lxw","madDog","neoe","randomArmy","soldierGo"]
	size=len(army)
	for x in range(size-1):
		for y in range(x+1, size):
			fn = "b_%s_%s.log"%(army[x],army[y])
			print('erl -pz ebin -eval erlbattle:start(%s,%s,{none,10,"%s"})\n'%(army[x],army[y],fn))
			print('start java -cp ../ebrep-bin/neoeebrep.jar neoe.ebrep.Main out/%s_%s %s \n'%(army[x],army[y],fn))

run()
