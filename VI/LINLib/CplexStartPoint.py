# This code follows how lpex1.py example provided by CPLEX distribution
import cplex
import sys
import numpy as np
from cplex.exceptions import CplexError
from gams import GamsWorkspace

# print(my_prob.parameters.advance.get())

def readFromGdx(dataName):
    ### Something to note
    #   1. I ignore problems tha contain ranged rows I did not know what they are 
    # (disp3.gdx, kent.gdx, lpl1.gdx, model11.gdx, nesm.gdx, orna1.gdx ... )
    #   2. I did not add objective constant as it seems unnecessary.

    # create gams workspace
    ws = GamsWorkspace()

    db2 = ws.add_database_from_gdx("./instances/{}".format(dataName))

    # all varialbe indices
    j = [rec.keys[0] for rec in db2["j"]]

    # all continuous variable indices (should be the same as j for LP problems)
    jc = [rec.keys[0] for rec in db2["jc"]]

    # all constriant indices
    i = [rec.keys[0] for rec in db2["i"]]

    # all >= constriant indices
    ig = [rec.keys[0] for rec in db2["ig"]]

    # all <= constriant indices
    il = [rec.keys[0] for rec in db2["il"]]

    # all == constriant indices
    ie = [rec.keys[0] for rec in db2["ie"]]

    # all ranged constraint indices
    ir = [rec.keys[0] for rec in db2["ir"]]

    # objective coefficient
    c = {rec.keys[0]: rec.value for rec in db2["c"]}

    # rhs for all constraints
    b = {rec.keys[0]: rec.value for rec in db2["b"]}

    # constraint matrix
    ac = {tuple(rec.keys): rec.value for rec in db2["ac"]}

    # check if this problem is to be solved
    if len(ir) > 0:
        print("There is ranged constraint. We do not deal with it, so we skip this problem.")
        print("Exiting...")
        sys.exit(-1)

    if len(j) != len(jc):
        print("It is not an LP problem. We skip this problem.")
        print("Exiting...")
        sys.exit(-1)

    return j, jc, i, ig, il, ie, c, b, ac

def constructLP(prob, var_index, continuous_var_index,
                constraint_index, geq_constraint_index,
                leq_constraint_index, eq_constraint_index,
                obj_coefficient, constraint_rhs, constraint_matrix):

    ######## Dealing with data
    my_obj = []
    my_rownames = []
    my_sense = ''
    my_rhs = []
    my_ub = []
    my_colnames = continuous_var_index

    # obj coefficient
    for varName in my_colnames:
        if varName in obj_coefficient.keys():
            my_obj.append(obj_coefficient[varName])
        else:
            my_obj.append(0.0)
        my_ub.append(cplex.infinity)

    # row name and row sense
    my_rownames = geq_constraint_index + leq_constraint_index + eq_constraint_index
    my_sense = 'G' * len(geq_constraint_index) + 'L' * len(leq_constraint_index) + 'E' * len(eq_constraint_index)

    # row rhs
    for constraintName in my_rownames:
        if constraintName in constraint_rhs:
            my_rhs.append(constraint_rhs[constraintName])
        else:
            my_rhs.append(0.0)

    # detailed row information
    rows = []

    for rowName in my_rownames:
        tempRepresentation = []
        tempRowCoef = []
        for varName in my_colnames:
            if (rowName,varName) in constraint_matrix:
                tempRowCoef.append(constraint_matrix[(rowName,varName)])
            else:
                tempRowCoef.append(0.0)
        tempRepresentation.append(my_colnames)
        tempRepresentation.append(tempRowCoef)
        rows.append(tempRepresentation)

    ####### Start feeding data into python structure

    # set objective sense
    prob.objective.set_sense(prob.objective.sense.minimize)

    # since lower bounds are all 0.0 (the default), lb is omitted here. 
    # For safety, I still add ub (with inf) because I cound not find documentation of how it should be called
    prob.variables.add(obj=my_obj, ub=my_ub, names=my_colnames)

    prob.linear_constraints.add(lin_expr=rows, senses=my_sense,
                                rhs=my_rhs, names=my_rownames)


def readProb(dataName):
    # create cplex env
    my_prob = cplex.Cplex()

    if (my_prob.parameters.advance.get() == 0):
        print("Skip solve. Please turn on advanced start for this experiment")
        print("Exiting...")
        sys.exit(-1)

    print(my_prob.parameters.lpmethod.help())
    my_prob.parameters.lpmethod.set(1)

    j, jc, i, ig, il, ie, c, b, ac = readFromGdx(dataName)

    constructLP(my_prob,
                j,
                jc,
                i,
                ig,
                il,
                ie,
                c,
                b,
                ac)

    my_prob.solve()
    s = my_prob.solution.get_values()

    my_prob = cplex.Cplex()

    pert = np.random.uniform(low = -0.5, high=0.5, size=len(s))

    my_prob.parameters.lpmethod.set(1)

    constructLP(my_prob,
                j,
                jc,
                i,
                ig,
                il,
                ie,
                c,
                b,
                ac)
    
    for i in range(len(s)):
        s[i] = s[i] + pert[i]

    my_prob.start.set_start([],
                            [],
                            s,
                            [],
                            [],
                            [])
    
    my_prob.solve()

if __name__ == "__main__":
    # check program input
    if len(sys.argv) != 2 or (not sys.argv[1].endswith(".gdx")):
        print("Program fails to run.")
        print("Usage: python3 run.py xxx.gdx")
        print("Exiting...")
        sys.exit(-1)

    # read in program data
    readProb(sys.argv[1])
    
