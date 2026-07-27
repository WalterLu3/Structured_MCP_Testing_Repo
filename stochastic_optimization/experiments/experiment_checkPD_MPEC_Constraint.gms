$ontext
Experiment to check if PD solves the problem
$offtext

option emp=reshop;

set loopN /l1*l%iterationLimit%/;

* step 1 run PD with multiple loops:


loop(loopN,
* p
riskProb.fx(n) = riskProb.l(n);


embeddedCode reshop:
primalNode: min objPrimal L(n) F(n) R(n) Z(n) objPrimalEqu deflvl(n)
endEmbeddedCode

solve mincostEMPManualPrimal using EMP;
abort$(mincostEMPManualPrimal.modelstat > 2) "Error: mincostEMPManualPrimal model did not solve";

riskProb.up(n) = (1-cvar_wt) * prob(n) + cvar_wt * prob(n)/(1-beta); 
riskProb.lo(n) = (1-cvar_wt) * prob(n);
riskProb.fx('n1') = 1;

* identify the sign of vi to include in the augmented D step
loop(n$(not sameas(n,'n1')),
* Fixed
    if(abs(f.up(n) - f.lo(n)) < 1e-8,
        f_vi.lo(n) = 0;
        f_vi.up(n) = 0;
* At lower bound
    elseif (abs(f.l(n) - f.lo(n)) < 1e-8),
        f_vi.lo(n) = 0;
        f_vi.up(n) = inf; 
* At upper bound
    elseif (abs(f.l(n) - f.up(n)) < 1e-8),
        f_vi.lo(n) = -inf;
        f_vi.up(n) = 0;     
* Between bounds
    else
        f_vi.lo(n) = -inf;
        f_vi.up(n) = inf;        
    );
);

* variable L
loop(n$(not sameas(n,'n1')),
* Fixed
    if(abs(l.up(n) - l.lo(n)) < 1e-8,
        l_vi.lo(n) = 0;
        l_vi.up(n) = 0;
* At lower bound
    elseif (abs(l.l(n) - l.lo(n)) < 1e-8),
        l_vi.lo(n) = 0;
        l_vi.up(n) = inf; 
* At upper bound
    elseif (abs(l.l(n) - l.up(n)) < 1e-8),
        l_vi.lo(n) = -inf;
        l_vi.up(n) = 0;     
* Between bounds
    else
        l_vi.lo(n) = -inf;
        l_vi.up(n) = inf;        
    );
);

* variable r

loop(n$(not sameas(n,'n1')),
* Fixed
    if(abs(r.up(n) - r.lo(n)) < 1e-8,
        r_vi.lo(n) = 0;
        r_vi.up(n) = 0;
* At lower bound
    elseif (abs(r.l(n) - r.lo(n)) < 1e-8),
        r_vi.lo(n) = 0;
        r_vi.up(n) = inf; 
* At upper bound
    elseif (abs(r.l(n) - r.up(n)) < 1e-8),
        r_vi.lo(n) = -inf;
        r_vi.up(n) = 0;     
* Between bounds
    else
        r_vi.lo(n) = -inf;
        r_vi.up(n) = inf;        
    );
);

* variable z
loop(n$(not sameas(n,'n1')),
* Fixed
    if(abs(z.up(n) - z.lo(n)) < 1e-8,
        z_vi.lo(n) = 0;
        z_vi.up(n) = 0;
* At lower bound
    elseif (abs(z.l(n) - z.lo(n)) < 1e-8),
        z_vi.lo(n) = 0;
        z_vi.up(n) = inf; 
* At upper bound
    elseif (abs(z.l(n) - z.up(n)) < 1e-8),
        z_vi.lo(n) = -inf;
        z_vi.up(n) = 0;     
* Between bounds
    else
        z_vi.lo(n) = -inf;
        z_vi.up(n) = inf;        
    );
);

L.fx(n) = L.l(n);
F.fx(n) = F.l(n);
R.fx(n) = R.l(n);
Z.fx(n) = Z.l(n);

* D
* if (card(loopN) <7,
* embeddedCode reshop:
* dualNode(n)$(not isLeafNode(n)): max objDual(n) riskProb(child)$(succ(n,child)) objDualEqu(n) convexCombEqu(n)
* equ: Nash(dualNode(n)$(not isLeafNode(n)))
* endEmbeddedCode

* solve mincostEMPManualDual using EMP;
* abort$(mincostEMPManualDual.modelstat > 2) "Error: mincostEMPManualDual model did not solve";
* );

if (card(loopN) > -1,


* take dual nlp step
mult_of_deflvl.fx(n) = deflvl.m(n);

option mpec=nlpec;
D_Step_MPEC_Constraint.optfile=3;

solve D_Step_MPEC_Constraint using mpec minimizing mpecObjVal;
abort$(D_Step_MPEC_Constraint.modelstat > 2) "Error: D_Step_MPEC_Constraint model did not solve";

);

L.lo(n) = 0;
F.lo(n) = 0;
R.lo(n) = 0;
Z.lo(n) = 0;
L.up(n) = +inf;
F.up(n) = +inf;
R.up(n) = +inf;
Z.up(n) = +inf;
R.up(n) = r_max;
L.up(n) = l_max;
L.fx(n)$(n.first) = l_start;
);

$ontext
objdual.l(child) = -( sum(nn$(nodePath(nn,child) and not sameas(nn,child)),
                        - prod(nnn$(nodePath(nn,nnn) and ord(nnn) > ord(child)), riskprob.l(nnn)) * ccostl(nn)));

embeddedCode python:
import graphviz

def drawTree(dot, nodes, arcs, y, objdual, f, z, floodCost, lowCost):
    dot.attr('node', shape='circle', style='filled', fillcolor='lightblue', fontname='Helvetica')
    dot.attr('edge', color='gray40', arrowsize='0.8')

    for node in nodes:
        if node == "n1":
            stage_cost = 0
        else:
            stage_cost = f.get(node, 0) * floodCost + z.get(node, 0) * lowCost
        label = "\n".join((
            node,
            f"disbenefit: {objdual.get(node, 0):,.5g}",
            f"stage cost: {stage_cost:,.5g}",
        ))
        dot.node(node, label=label)

    for start_node, end_node in arcs:
        dot.edge(start_node, end_node, label=f"{y.get(end_node, 0):,.5g}")


db = gams.db

nodes = [rec.keys[0] for rec in db["n"]]
arcs = [(rec.keys[0], rec.keys[1]) for rec in db["succ"]]

floodCost = db["floodCost"].first_record().value
lowCost = db["lowCost"].first_record().value

y = {}
objdual = {}
f = {}
z = {}

for rec in db["riskprob"]:
    y[rec.keys[0]] = rec.level

for rec in db["objdual"]:
    objdual[rec.keys[0]] = rec.level

for rec in db["f"]:
    f[rec.keys[0]] = rec.level

for rec in db["z"]:
    z[rec.keys[0]] = rec.level

print(f"Found {len(nodes)} nodes and {len(arcs)} arcs.")

dot = graphviz.Digraph('GamsTree', comment='GAMS Tree Visualization')
dot.attr(rankdir='LR', size='10,8', label='Tree with objdual and stage cost', fontsize='20')

drawTree(dot, nodes, arcs, y, objdual, f, z, floodCost, lowCost)

output_filename = 'seed2_pdMPEC_3'
try:
    dot.render(output_filename, view=True, format='pdf', cleanup=True)
    print(f"Successfully created graph visualization: '{output_filename}.pdf'")
except Exception as e:
    print(f"Error during Graphviz rendering: {e}")

endEmbeddedCode

$offtext

* need to negate the convexCombEqu(n) multipliers
convexCombEqu.m(n) = rho.l(n);
*convexCombEqu.m(n) = -convexCombEqu.m(n);


* step 2: solve mincostEMPManual with final values 
*         to check if it is solved
embeddedCode reshop:
primalNode: min objPrimal L(n) F(n) R(n) Z(n) objPrimalEqu deflvl(n)
dualNode(n)$(not isLeafNode(n)): max objDual(n) riskProb(child)$(succ(n,child)) objDualEqu(n) convexCombEqu(n)
equ: Nash(primalNode, dualNode(n)$(not isLeafNode(n)))
endEmbeddedCode

* specify optfile to only allow 1 iteration
$onEcho > reshop.opt
subsolveropt 1
$offEcho

$onEcho > path.opt
crash_method none
prox_pert 0
crash_pert no
minor_iter_limit 1
major_iter_limit 0
$offEcho

mincostEMPManual.optfile = 1;

solve mincostEMPManual using EMP;



