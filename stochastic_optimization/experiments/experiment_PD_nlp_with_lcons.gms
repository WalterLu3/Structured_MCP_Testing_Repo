$ontext
Experiment to check if PD solves the problem
$offtext

option emp=reshop;

set loopN /l1*l%iterationLimit%/;

* step 1 run PD with multiple loops:

riskprob.l(n) = prob(n);

* option emp = reshop;
* embeddedCode reshop:
* primalNode: min objPrimal L(n) F(n) R(n) Z(n) objPrimalEqu deflvl(n)
* dualNode(n)$(not isLeafNode(n)): max objDual(n) riskProb(child)$(succ(n,child)) objDualEqu(n) convexCombEqu(n)
* equ: Nash(primalNode, dualNode(n)$(not isLeafNode(n)))
* endEmbeddedCode


* solve mincostEMPManual using EMP;

* display objPrimal.l;

* display riskProb.l;
* display convexCombEqu.m;



loop(loopN,

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


* take dual nlp step
mult_of_deflvl.fx(n) = deflvl.m(n);

option nlp=baron;
solve dualNLP using nlp maximizing objDualComp_nlp;
abort$(dualNLP.modelstat > 2) "Error: dualNLP model did not solve";


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

* display FOONC_F_GEQ_nlp.m, FOONC_F_LEQ_nlp.m, FOONC_L_GEQ_nlp.m, FOONC_L_LEQ_nlp.m, FOONC_R_GEQ_nlp.m, FOONC_R_LEQ_nlp.m, FOONC_Z_GEQ_nlp.m, FOONC_Z_LEQ_nlp.m;
* display nodePath;
* $exit



* need to negate the convexCombEqu(n) multipliers and rescale 
*convexCombEqu.m(n) = -convexCombEquAlternative_nlp.m(n);
*convexCombEqu.m(n) = -convexCombEquAlternative_nlp.m(n) * prod(child$(nodePath(n,child) and not sameas(n,child)), riskProb.l(child));

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