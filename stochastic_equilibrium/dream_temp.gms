
set notLeafNotRoot(n);
notLeafNotRoot(n) = no;
notLeafNotRoot(n)$(not leafn(n) and sn(n)) = yes;

embeddedcode reshop:
realAgent(a,'n0'): min obj_dynamic(a,'n0') + riskAgent(a,'n0').valfn
                    x(a,i,'n0') 
                    defobj_dynamic(a,'n0') 
realAgent(a,n)$(notLeafNotRoot(n)): min obj_dynamic(a,n) + riskAgent(a,n).valfn
                    x(a,i,n) 
                    q(a,i,n) 
                    s(a,i,n)
                    defobj_dynamic(a,n) 
                    defFlow(a,i,n)
realAgent(a,n)$(leafn(n)): min obj_dynamic(a,n)
                    x(a,i,n)
                    q(a,i,n) 
                    s(a,i,n)
                    defobj_dynamic(a,n) 
                    defFlow(a,i,n)
riskAgent(a,n)$(not leafn(n)): MP('ecvarup', realAgent(a,child).valfn$succ(n,child),
                                  tail=tail, 
                                  risk_wt=%lambda%, 
                                  prob=prob(child)$succ(n,child))
priceAgent(i,n)$(sn(n)): vi defSupplydemand(i,n) p(i,n)
equ: Nash(realAgent(a,'n0'),priceAgent(i,n)$(sn(n)))
endembeddedcode


gasEnEqulibrium_dynamic.justScrDir = 1;
solve gasEnEqulibrium_dynamic using emp;

* how do we control the model reformulation
* how do we visualization => scheme
* how should we access the node name and set call the agent
* gather idea of the problem
* where should the resulting solution reside

* PATH
embeddedcode python:
import reshop as rhp

rhp.opt_setfromstr('ovf_reformulation equilibrium')

# call reshop function using str
gasEnEqulibrium = rhp.Model(r"%gams.scrdir%gamscntr.%gams.scrext%")
gasEnEqulibrium.solve(r"%gams.scrdir%savepoint.gdx")

endembeddedcode

execute_loadpoint '%gams.scrdir%savepoint.gdx';

************************************************

* PD
embeddedcode python:

import IPython


# ### install pip
# gams.get('a')
# gams.get('i')

rhp.opt_setfromstr('ovf_reformulation equilibrium')

m = rhp.Model(r"%gams.scrdir%gamscntr.%gams.scrext%")
#gasEnEqulibrium.solve(r"%gams.scrdir%savepoint.gdx", )

gasEnEqulibrium_reformulated = rhp.Model(rhp.BackendGamsGmo)

rhp.process(m, gasEnEqulibrium_reformulated)

# set in the embedded code

IPython.embed(colors="neutral")

#N, E= gasEnEqulibrium_reformulated.empdag.to_dict()

#for k, v in N.items():
    
# "riskAgent('a1','n0')"

primalAgents = []
dualAgents = {}

# gasEnEqulibrium_reformulated.empdag 
for nodeName, nodeObj in gasEnEqulibrium_reformulated.empdag.items():
    if (nodeName.startswith("riskAgent")):
         dualAgents[nodeName] = nodeObj
    elif ("n0" in nodeName):
         primalAgents.append(nodeObj)


#for n_temp in n:
#    for i_temp in i:
#        if sn[n_temp]:    
#            primalAgents.append(priceAgent(i_temp, n_temp))

# Create the primal MOPEC
primalModel = rhp.Nash(primalAgents, subtree=True)

dualModels = {}
dualModelsPerStage = {} 

for k,v in dualAgents:
    singleRisk =  rhp.Model(v, subtree=False)
    dualModels[k] = singleRisk
    # option 1: v.edge -> returns the edges as a dictionary + construct tree + DFS/BFS
    # option 2: load t via t = gams.get('t')
    # HACK: extract node from name:  nn = k.strip('(')[1].split(',')[1]
    # get stage as ...
    
     # get tt here for the dualModel[k]

    if tt not in dualModelsPerStage:
          dualModelsPerStage[tt] = []
    dualModelsPerStage[tt].append(singleRisk)

# tlist needs to define and needs to be ordered chronically
t_revered = reversed(tlist)

iterN = 0
iterMax = 10
# For PD-PATH
#lastResidual = float("inf")
#primalHistory = None
while iterN < iterMax:

    # solve primal model
    primalModel.solve(push_to_container=True, pull_from_container=True)
    
    # update risk probabilities
    
    for tt in t_reversed:
         for m2 in dualModelsPerStage[tt]:
              m2.solve(push_to_container=True, pull_from_container=True)

# PD
    if gasEnEqulibrium_reformulated.getResidual() < 1e-6:
         break
    iterN += 1
    
# PD-PATH
#     currentResidual = gasEnEqulibrium_reformulated.getResidual()
#     if lastResidual > currentResidual:
#      lastResidual = currentResidual
#      history = gasEnEqulibrium_reformulated.getVars()
#    else:
#      gasEnEqulibrium_reformulated.setVars(history)

#gasEnEqulibrium_reformulated.solve()

################################################################

# PD-CC-PATH
riskHistory = {}
for k in dualAgents:
     riskHistory[k] = []


# In the following, we assume that 'solve' does not pull

iterN = 0
iterMax = 10
#lastResidual = float("inf")
#primalHistory = None
while iterN < iterMax:

    # solve primal model
    primalModel.solve(pull_from_container=True, push_to_container=True)
    
    for tt in t_reversed:
         for m2 in dualModelsPerStage[tt]:
              m2.solve(push_to_container=True, pull_from_container=True)

    res = gasEnEqulibrium_reformulated.getResidual()
    if (res < 1e-6):
         break;
    # if res increases -> do something smart

    for risk in dualModels.values():
         riskSolution = risk.getVars()
         if len(riskHistory[k]) == 3:
             riskHistory[k].pop(0)
         riskHistory[k].append(riskSolution)
         # compute combination
         riskValueUpdate = average(riskHistory[k], weight=[.5, .3, .2])
         primalModel.setVars(riskValueUpdate)

    iter += 1

# dump gdx file

# create a gams model
gamsModel = rhp.Model(rhp.BackendGamsGmo)

gasEnEqulibrium.exportModel(gamsModel) # create a gmo and based on the gmo create a gdx

rhp.gms_writesol2gdx(gamsModel, r"%gams.scrdir%savepoint.gdx")

endembeddedcode

execute_loadpoint '%gams.scrdir%savepoint.gdx';





***while gasEnEqulibrium.getResidual() > 1e-6:
***
***    # solve primal model
***    primalModel.solve()
***
***    # solve dual model
***    dualModel.solve()


























* PD ( the solve does not create a new model )
embeddedcode python:

primalAgents = [P1, P2, VI1, VI2]
dualAgents = [R1, R2]


primalModel = fullModel.newModel(primalAgents)

dualModel = fullModel.newModel(dualAgents)

fullModel.solve(type='evaluate')

while not fullModel.solvestat == 1:

    # solve primal model
    primalModel.solve()

    primalSolution = primalModel.getvals()

    # update values in dual and main model

    dualModel.setvals(primalSolution)

    fullModel.setvals(primalSolution)

    # solve dual model
    dualModel.solve()

    dualSolution = dualModel.getvals()

    # update values in primal and main model
    primalModel.setvals(dualSolution)
    
    fullModel.setvals(dualSolution)


    fullModel.solve()
endembeddedcode



* PD ( the solve does create a new model )
embeddedcode python:

primalAgents = [P1, P2, VI1, VI2]
dualAgents = [R1, R2]

evaluateModel = fullModel.solve(Nash, type='nodal')

while not evaluateModel.solvestat == 1:

    # solve primal model
    primalModel = primalModel.solve(Nash, type='subtree')

    primalSolution = primalModel.getvals()

    # update values in dual and main model

    dualModel.setvals(primalSolution)

    fullModel.setvals(primalSolution)

    # solve dual model
    dualModel = dualModel.solve(Nash, type='subtree')

    dualSolution = dualModel.getvals()

    # update values in primal and main model
    primalModel.setvals(dualSolution)
    
    fullModel.setvals(dualSolution)

    evaluateModel = fullModel.solve(type='nodal')

# 
endembeddedcode

execute_loadpoint '%gams.scrdir%savepoint.gdx';





# PATH, PATH-RN, PD, PD-PATH, PD-CC-PATH

# gasEnEqulibrium_reformulated