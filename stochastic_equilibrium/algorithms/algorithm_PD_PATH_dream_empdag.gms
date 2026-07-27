
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

*****************  PATH  ***********************
embeddedcode python:
import reshop as rhp

rhp.opt_setfromstr('ovf_reformulation equilibrium')

# call reshop function using str
gasEnEqulibrium = rhp.Model(r"%gams.scrdir%gamscntr.%gams.scrext%")
gasEnEqulibrium.solve(r"%gams.scrdir%savepoint.gdx")

endembeddedcode

execute_loadpoint '%gams.scrdir%savepoint.gdx';

**************  PATH ENDS  **********************

***************  PD-PATH  ***********************
embeddedcode python:

import IPython
IPython.embed(colors="neutral")

import reshop as rhp


# Step 0. Grab needed set from gams database

# map from node to time
nodeToTime = {}
nt = list(gams.get('nt'))
for n, t in nt:
     nodeToTime[n] = t

tlist = list(gams.get('t'))

# Step 1. set the option and load the model from GAMS
rhp.opt_setfromstr('ovf_reformulation equilibrium')

m = rhp.Model(r"%gams.scrdir%gamscntr.%gams.scrext%")


# Step 2. perform automatic reformulation
gasEnEqulibrium_reformulated = rhp.Model(rhp.BackendGamsGmo)

rhp.process(m, gasEnEqulibrium_reformulated)

# Step 3. prepare data structure to store primal and dual model
primalAgents = []
dualAgents = {}
dualAgentToTime = {}
nashChildren = []
for nodeName, nodeObj in gasEnEqulibrium_reformulated.empdag.items():
     # assume nodeName is like "riskAgent(a1,n1)"
     # get n from the node name
     # TODO: have a more robust extraction: via regex get the argument in the () and then split
     nn = nodeName.split(",")[1][:-1] # :-1 to exclude the last ")"
     if (nodeName.startswith("riskAgent")):
          dualAgents[nodeName] = nodeObj
          dualAgentToTime[nodeName] = nodeToTime[nn]
     elif (nodeName.startswith("realAgent")):
          primalAgents.append(nodeName)
          if (nn == "n0"):
               nashChildren.append(nodeName)
     elif (nodeName.startswith("priceAgent")):
          primalAgents.append(nodeName)
          nashChildren.append(nodeName)

primalAgents.append("equ")
# Create the primal MOPEC
* primalModel = rhp.Model(rhp.Nash(primalAgents, include_children=True), \
*                         include_children=True)

primalEMPDAG = gasEnEqulibrium_reformulated.empdag.filter(nodes = primalAgents)
primalModel = rhp.Model(primalEMPDAG)

* rhp.Model(singleNode, include_children=True)
*     b - c
*   /
* a 
*   \ 
*     d - e

* rhp.Model(d, include_children=True)

* d-e
* N = rhp.Nash([b,d], include_children=True)
* rhp.Model(N, includeChildren=False)

* rhp.Model(Node)
* rhp.Model(Nodes)

* N = rhp.Nash([b,d])
*     b 
*   /
* N 
*   \ 
*     d 
* rhp.Model(N, include_children=True)

*     b - c
*   /
* N 
*   \ 
*     d - e

#1. create a Nash node and using the empdag nodes in primalAgents, it is specifying the children node 
#   of the Nash node
#2. include_children=True means that we will create a model object including the 
#   Nash node and its children node

# Constraint: that the nodes in primalAgents are all from the same EMPDAG

#rhp.Model(rhp.nash(primalAgents),  include_children=True)



# Store the dual subproblems according to time stages
dualModels = {}         # dictionary of model {nodeName: reshop model for a single node}
dualModelsPerStage = {} # dictionary of list  {time stage: list of reshop models}

for k,v in dualAgents.items():
     singleDualEMPDAG = gasEnEqulibrium_reformulated.empdag.filter(nodes = [k])
     singleRisk = rhp.Model(singleDualEMPDAG)
     dualModels[k] = singleRisk

     # get tt here for the dualModel[k]
     tt = dualAgentToTime[k]

     if tt not in dualModelsPerStage:
          dualModelsPerStage[tt] = []
     dualModelsPerStage[tt].append(singleRisk)

# tlist needs to be defined and needs to be ordered chronically
t_reversed = reversed(tlist)

iterN = 0
iterMax = 10

# Step 4: enter the PD loop
lastSolution = None
lastResidual = float("inf")
while iterN < iterMax:

     # solve primal model
     primalModel.solve(push_to_parent_container=True, pull_from_parent_container=True)
 
     # update risk probabilities (solve dual model)
     for tt in t_reversed:
          for m2 in dualModelsPerStage[tt]:
               m2.solve(push_to_parent_container=True, pull_from_parent_container=True)

     currentResidual = gasEnEqulibrium_reformulated.getResidual()
 
     # exit loop when residual increases
     if currentResidual > lastResidual:
          # recover the last solution as the residual is smaller
          gasEnEqulibrium_reformulated.setVars(lastSolution,
                                               updateLevel=True,
                                               updateMultiplier=True)
          break
     else:
          currentResidual = lastResidual
          lastSolution = gasEnEqulibrium_reformulated.getVars()

     iterN += 1
    
# Step 5. perform final PATH solve
gasEnEqulibrium_reformulated.solve(push_to_parent_container=True, pull_from_parent_container=True)

endembeddedcode

**************  PD-PATH ENDS  *******************

********************** Below is future work ***************************

* riskHistory = {}
* for k in dualAgents:
*      riskHistory[k] = []


* # In the following, we assume that 'solve' does not pull

* iterN = 0
* iterMax = 10

* while iterN < iterMax:

*     # solve primal model
*     primalModel.solve(pull_from_parent_container=False, push_to_parent_container=True)
    
*     for tt in t_reversed:
*          for m in dualModelsPerStage[tt]:
*               m.solve(push_to_parent_container=True, pull_from_parent_container=True)

*     res = gasEnEqulibrium.getResidual()
*     if (res < 1e-6):
*          break;
*     # if res increases -> do something smart

*     for risk in dualModels.values():
*          riskSolution = risk.getVars()
*          if len(riskHistory[k]) == 3:
*              riskHistory[k].pop(0)
*          riskHistory[k].append(riskSolution)
*          # compute combination
*          riskValueUpdate = average(riskHistory[k], weight=[.5, .3, .2])
*          primalModel.setVars(riskValueUpdate)

*     iter += 1

* # dump gdx file

* # create a gams model
* gamsModel = rhp.Model(rhp.BackendGamsGmo)

* gasEnEqulibrium.exportModel(gamsModel) # create a gmo and based on the gmo create a gdx

* rhp.gms_writesol2gdx(gamsModel, r"%gams.scrdir%savepoint.gdx")

* endembeddedcode

* execute_loadpoint '%gams.scrdir%savepoint.gdx';





***while gasEnEqulibrium.getResidual() > 1e-6:
***
***    # solve primal model
***    primalModel.solve()
***
***    # solve dual model
***    dualModel.solve()


























* PD ( the solve does not create a new model )
* embeddedcode python:

* primalAgents = [P1, P2, VI1, VI2]
* dualAgents = [R1, R2]


* primalModel = fullModel.newModel(primalAgents)

* dualModel = fullModel.newModel(dualAgents)

* fullModel.solve(type='evaluate')

* while not fullModel.solvestat == 1:

*     # solve primal model
*     primalModel.solve()

*     primalSolution = primalModel.getvals()

*     # update values in dual and main model

*     dualModel.setvals(primalSolution)

*     fullModel.setvals(primalSolution)

*     # solve dual model
*     dualModel.solve()

*     dualSolution = dualModel.getvals()

*     # update values in primal and main model
*     primalModel.setvals(dualSolution)
    
*     fullModel.setvals(dualSolution)


*     fullModel.solve()
* endembeddedcode



* * PD ( the solve does create a new model )
* embeddedcode python:

* primalAgents = [P1, P2, VI1, VI2]
* dualAgents = [R1, R2]

* evaluateModel = fullModel.solve(Nash, type='nodal')

* while not evaluateModel.solvestat == 1:

*     # solve primal model
*     primalModel = primalModel.solve(Nash, type='subtree')

*     primalSolution = primalModel.getvals()

*     # update values in dual and main model

*     dualModel.setvals(primalSolution)

*     fullModel.setvals(primalSolution)

*     # solve dual model
*     dualModel = dualModel.solve(Nash, type='subtree')

*     dualSolution = dualModel.getvals()

*     # update values in primal and main model
*     primalModel.setvals(dualSolution)
    
*     fullModel.setvals(dualSolution)

*     evaluateModel = fullModel.solve(type='nodal')

* # 
* endembeddedcode

* execute_loadpoint '%gams.scrdir%savepoint.gdx';





* PATH, PATH-RN, PD, PD-PATH, PD-CC-PATH

* gasEnEqulibrium_reformulated
