$ontext
Experiment to check if PD solves the problem
$offtext

option emp=reshop;

set loopN /l1*l%iterationLimit%/;

* step 1 run PD with multiple loops:

riskprob.l(n) = prob(n);

* add ppterm * || x ||^2 to objective

scalar loopCount /0/;
$ontext
ppterm = 0;

option emp = reshop;
embeddedCode reshop:
primalNode: min objPrimal L(n) F(n) R(n) Z(n) objPrimalEqu deflvl(n)
dualNode(n)$(not isLeafNode(n)): max objDual(n) riskProb(child)$(succ(n,child)) objDualEqu(n) convexCombEqu(n)
equ: Nash(primalNode, dualNode(n)$(not isLeafNode(n)))
endEmbeddedCode


solve mincostEMPManual using EMP;



display objPrimal.l;


ppterm = %ppterm%; 

* display riskProb.l;
* display convexCombEqu.m;

$offtext


$macro diffValue \
    sum(n, \
        abs(F_record(n) - F.l(n)) + \
        abs(L_record(n) - L.l(n)) + \
        abs(R_record(n) - R.l(n)) + \
        abs(Z_record(n) - Z.l(n)))


* F_record(n) = F.l(n);
* L_record(n) = L.l(n);
* R_record(n) = R.l(n);
* Z_record(n) = Z.l(n);
* riskprob_record(n) = riskprob.l(n);

F_record(n) = 0;
L_record(n) = 0;
R_record(n) = 0;
Z_record(n) = 0;
riskprob_record(n) = riskprob.l(n);

$ontext
display l.l;

F.l(n) = max(F.l(n) + uniform(-0.01,0.01), F.lo(n));
L.l(n) = min(max(L.l(n) + uniform(-0.01,0.01), L.lo(n)), L.up(n));
R.l(n) = min(max(R.l(n) + uniform(-0.01,0.01), R.lo(n)), R.up(n));
Z.l(n) = max(Z.l(n) + uniform(-0.01,0.01), Z.lo(n));



scalar ffff, rrrr;
ffff = diffValue;



* take dual nlp step
mult_of_deflvl.fx(n) = deflvl.m(n);

option nlp=conopt;
solve dualNLP using nlp maximizing objDualComp_nlp;
abort$(dualNLP.modelstat > 2) "Error: dualNLP model did not solve";


rrrr = sum(n, abs(riskprob.l(n) - riskprob_record(n)));

display ffff,rrrr;


* solve P
riskProb.fx(n) = riskProb.l(n);


embeddedCode reshop:
primalNode: min objPrimal L(n) F(n) R(n) Z(n) objPrimalEqu deflvl(n)
endEmbeddedCode

solve mincostEMPManualPrimal using EMP;
abort$(mincostEMPManualPrimal.modelstat > 2) "Error: mincostEMPManualPrimal model did not solve";


riskProb.up(n) = (1-cvar_wt) * prob(n) + cvar_wt * prob(n)/(1-beta); 
riskProb.lo(n) = (1-cvar_wt) * prob(n);
riskProb.fx('n1') = 1;

ffff = diffValue;

display ffff;
$offtext

$ontext

display F_record, F.l, L_record, L.l, Z_record, Z.l;


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

output_filename = 'seed1_PD_nlp_solve'
try:
    dot.render(output_filename, view=True, format='pdf', cleanup=True)
    print(f"Successfully created graph visualization: '{output_filename}.pdf'")
except Exception as e:
    print(f"Error during Graphviz rendering: {e}")

endEmbeddedCode
$offtext
riskprob.l(n) = prob(n);

L.l(n)$(not n.first) = 0;
F.l(n) = 0;
R.l(n) = 0;
Z.l(n) = 0;

scalar
    recordpterm /0/
;

loop(loopN,

loopCount  = loopCount + 1;
* solve P
riskProb.fx(n) = riskProb.l(n);

pterm = pterm * 2;
recordPterm = pterm;


embeddedCode reshop:
primalNode: min objPrimal L(n) F(n) R(n) Z(n) objPrimalEqu deflvl(n)
endEmbeddedCode

solve mincostEMPManualPrimal using EMP;
*abort$(mincostEMPManualPrimal.modelstat > 2) "Error: mincostEMPManualPrimal model did not solve";

* algo
F_record(n) = F.l(n);
L_record(n) = L.l(n);
R_record(n) = R.l(n);
Z_record(n) = Z.l(n);

riskProb.up(n) = (1-cvar_wt) * prob(n) + cvar_wt * prob(n)/(1-beta); 
riskProb.lo(n) = (1-cvar_wt) * prob(n);
riskProb.fx('n1') = 1;


* take dual nlp step
mult_of_deflvl.fx(n) = deflvl.m(n);

option nlp=conopt;
solve dualNLP using nlp maximizing objDualComp_nlp;
*abort$(dualNLP.modelstat > 2) "Error: dualNLP model did not solve";


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

solve findRho using nlp minimizing dummyObj;


if (findRho.modelstat < 2,
* check if solved
convexCombEqu.m(n) = rho.l(n);
);


* solve mincostEMPManual with final values 
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

if(mincostEMPManual.modelstat < 3,
    break;
);


);

display mincostEMPManual.objval;
display loopCount;
display  mincostEMPManual.modelstat;

* if(mincostEMPManual.modelstat > 2,
*     abort$(1 > 0) "Error: whole problem not solved";
* );


* display FOONC_F_GEQ_nlp.m, FOONC_F_LEQ_nlp.m, FOONC_L_GEQ_nlp.m, FOONC_L_LEQ_nlp.m, FOONC_R_GEQ_nlp.m, FOONC_R_LEQ_nlp.m, FOONC_Z_GEQ_nlp.m, FOONC_Z_LEQ_nlp.m;
* display nodePath;
* $exit


* need to negate the convexCombEqu(n) multipliers and rescale 
*convexCombEqu.m(n) = -convexCombEquAlternative_nlp.m(n);
*convexCombEqu.m(n) = -convexCombEquAlternative_nlp.m(n) * prod(child$(nodePath(n,child) and not sameas(n,child)), riskProb.l(child));

$exit
solve findRho using nlp minimizing dummyObj;
convexCombEqu.m(n) = rho.l(n);

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

display objprimal.l;



