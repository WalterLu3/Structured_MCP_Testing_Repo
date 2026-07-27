
set notLeafNotRoot(n);
notLeafNotRoot(n) = no;
notLeafNotRoot(n)$(not leafn(n) and sn(n)) = yes;

embeddedcode reshop:
realAgent(a,'n0'): min obj_dynamic(a,'n0') + riskAgent(a,'n0').valfn
                    x(a,i,'n0') 
                    defobj_dynamic(a,'n0') 
                    defFlow(a,i,'n0')
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

# how do we control the model reformulation
# how do we visualization => scheme
# how should we access the node name and set call the agent
# gather idea of the problem
# where should the resulting solution reside

# PATH
embeddedcode python:
import reshop as rhp

rhp.opt_setfromstr('ovf_reformulation equilibrium')

# call reshop function using str
gasEnEqulibrium = rhp.Model(r"%gams.scrdir%gamscntr.%gams.scrext%")
gasEnEqulibrium.solve(r"%gams.scrdir%savepoint.gdx")

endembeddedcode

execute_loadpoint '%gams.scrdir%savepoint.gdx';



# PD
embeddedcode python:

# ### install pip
# gams.get('a')
# gams.get('i')

rhp.opt_setfromstr('ovf_reformulation equilibrium')

m = rhp.Model(r"%gams.scrdir%gamscntr.%gams.scrext%")
#gasEnEqulibrium.solve(r"%gams.scrdir%savepoint.gdx", )

gasEnEqulibrium = rhp.Model(rhp.BACKEND)

rhp.process(m, gasEnEqulibrium_reformulated)

primalAgents = []
dualAgents = []

# set in the embedded code

N, E= gasEnEqulibrium_reformulated.empdag.as_dict()

for k, v in N.items():
    
"riskAgent('a1','n0')"

for a_temp in a:
    primalAgents.append("realAgent({},'n0')".format("'atemp'"))
    dualAgents.append(riskAgent(a_temp, 'n0'))

for n_temp in n:
    for i_temp in i:
        if sn[n_temp]:    
            primalAgents.append(priceAgent(i_temp, n_temp))

primalModel = gasEnEqulibrium.Model(primalAgents, subtree=True)

dualModel = gasEnEqulibrium.Model(dualAgents, subtree=True)


while gasEnEqulibrium.getResidual() > 1e-6:

    # solve primal model
    primalModel.solve()

    primalSolution = primalModel.getVars()

    # update values in dual and main model

    dualModel.setVars(primalSolution) # set parameters

    gasEnEqulibrium.setVars(primalSolution)

    # solve dual model
    dualModel.solve()

    dualSolution = dualModel.getVars()

    # update values in primal and main model
    primalModel.setVars(dualSolution) # set parameters
    
    gasEnEqulibrium.setVars(dualSolution)

# dump gdx file

# create a gams model
gamsModel = rhp.Model(rhp.BackendGamsGmo)

gasEnEqulibrium.exportModel(gamsModel) # create a gmo and based on the gmo create a gdx

rhp.gms_writesol2gdx(gamsModel, r"%gams.scrdir%savepoint.gdx")

endembeddedcode

execute_loadpoint '%gams.scrdir%savepoint.gdx';





while gasEnEqulibrium.getResidual() > 1e-6:

    # solve primal model
    primalModel.solve()

    # solve dual model
    dualModel.solve()


























# PD ( the solve does not create a new model )
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



# PD ( the solve does create a new model )
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






