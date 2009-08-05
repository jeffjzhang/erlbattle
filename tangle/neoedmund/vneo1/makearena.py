#!/bin/python
def run():
	army=["englandArmy","feardFarmers","hwh.triple","lxw","madDog","neoe","randomArmy","soldierGo"]
	size=len(army)
	a=[]
	b=[]
	for x in range(size-1):
		for y in range(x+1, size):
			fn = "b_%s_%s.log"%(army[x],army[y])
			a.append('erl -pz ebin -eval erlbattle:start(%s,%s,{20,100,"%s"})'%(army[x],army[y],fn))
			b.append('start java -cp ../ebrep-bin/neoeebrep.jar neoe.ebrep.Main out/%s_%s %s'%(army[x],army[y],fn))
	print("\n".join(a))		
	print("\n".join(b))

run()
