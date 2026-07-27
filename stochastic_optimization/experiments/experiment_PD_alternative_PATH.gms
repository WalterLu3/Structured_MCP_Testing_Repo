$ontext
Experiment to check if PD solves the problem
$offtext

option emp=reshop;

option reslim=1200;

set loopN /l1*l%iterationLimit%/;

* step 1 run PD with multiple loops:

riskprob.l(n) = prob(n);

* add ppterm * || x ||^2 to objective

scalar loopCount /0/;


$macro diffValue \
    sum(n, \
        abs(F_record(n) - F.l(n)) + \
        abs(L_record(n) - L.l(n)) + \
        abs(R_record(n) - R.l(n)) + \
        abs(Z_record(n) - Z.l(n)))

F_record(n) = 0;
L_record(n) = 0;
R_record(n) = 0;
Z_record(n) = 0;
riskprob_record(n) = riskprob.l(n);

riskprob.l(n) = prob(n);

L.l(n)$(not n.first) = 0;
F.l(n) = 0;
R.l(n) = 0;
Z.l(n) = 0;

scalar
    recordpterm /0/
    lastKKTViolation
    currentKKTViolation
;

lastKKTViolation = +inf;

loop(loopN,

loopCount  = loopCount + 1;
* solve P
riskProb.fx(n) = riskProb.l(n);

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

currentKKTViolation = sum(n,
                           f_geq_penalty.l(n) * f_geq_penalty.l(n) +
                           f_leq_penalty.l(n) * f_leq_penalty.l(n) +
                           l_geq_penalty.l(n) * l_geq_penalty.l(n) +
                           l_leq_penalty.l(n) * l_leq_penalty.l(n) +
                           r_geq_penalty.l(n) * r_geq_penalty.l(n) +
                           r_leq_penalty.l(n) * r_leq_penalty.l(n) +
                           z_geq_penalty.l(n) * z_geq_penalty.l(n) +
                           z_leq_penalty.l(n) * z_leq_penalty.l(n) 
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
subsolveropt 2
$offEcho

$onEcho > path.op2
crash_method none
prox_pert 0
crash_pert no
minor_iter_limit 1
major_iter_limit 0
$offEcho

mincostEMPManual.optfile = 2;

solve mincostEMPManual using EMP;

if(mincostEMPManual.modelstat < 3,
    break;
);

if(currentKKTViolation > 0.1 * lastKKTViolation,
    lastKKTViolation = currentKKTViolation;
);

);


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
$offEcho

mincostEMPManual.optfile = 1;

solve mincostEMPManual using EMP;

display objprimal.l;

scalar t_used;
t_used = timeElapsed;

display t_used;



