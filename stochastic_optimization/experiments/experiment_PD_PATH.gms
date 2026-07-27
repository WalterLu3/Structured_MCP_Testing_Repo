$ontext
Perform PD-PATH on the Clear Lake Example
$offtext

option emp=reshop;

option reslim=1200;

set loopN /l1*l%iterationLimit%/;

* step 1 run PD with multiple loops:
riskProb.l(n) = prob(n);

scalar 
    lastResidual
    currentResidual
;
lastResidual = +inf;

parameter
    L_record(n)
    F_record(n)
    R_record(n)
    Z_record(n)
    deflvl_m_record(n)
    riskprob_record(n)
    convexCombEqu_m_record(n)
;

L_record(n) = 0;
F_record(n) = 0;
R_record(n) = 0;
Z_record(n) = 0;
deflvl_m_record(n) = 0;
riskprob_record(n) = 0;
convexCombEqu_m_record(n) = 0;

loop(loopN,

riskProb.fx(n) = riskProb.l(n);


embeddedCode reshop:
primalNode: min objPrimal L(n) F(n) R(n) Z(n) objPrimalEqu deflvl(n)
endEmbeddedCode

solve mincostEMPManualPrimal using EMP;
abort$(mincostEMPManualPrimal.modelstat > 2) "Error: mincostEMPManualPrimal model did not solve";

riskProb.up(n) = (1-cvar_wt) * prob(n) + cvar_wt * prob(n)/(1-beta); 
riskProb.lo(n) = (1-cvar_wt) * prob(n);
riskProb.fx('n1') = 1;

L.fx(n) = L.l(n);
F.fx(n) = F.l(n);
R.fx(n) = R.l(n);
Z.fx(n) = Z.l(n);


embeddedCode reshop:
dualNode(n)$(not isLeafNode(n)): max objDual(n) riskProb(child)$(succ(n,child)) objDualEqu(n) convexCombEqu(n)
equ: Nash(dualNode(n)$(not isLeafNode(n)))
endEmbeddedCode

solve mincostEMPManualDual using EMP;
*abort$(mincostEMPManualDual.modelstat > 2) "Error: mincostEMPManualDual model did not solve";

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

* evaluate residual 

embeddedCode reshop:
primalNode: min objPrimal L(n) F(n) R(n) Z(n) objPrimalEqu deflvl(n)
dualNode(n)$(not isLeafNode(n)): max objDual(n) riskProb(child)$(succ(n,child)) objDualEqu(n) convexCombEqu(n)
equ: Nash(primalNode, dualNode(n)$(not isLeafNode(n)))
endEmbeddedCode

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
convexCombEqu.m(n) = -convexCombEqu.m(n);
solve mincostEMPManual using EMP;

currentResidual = mincostEMPManual.objval;

if (currentResidual < 1e-6,
    convexCombEqu_m_record(n) = convexCombEqu.m(n);
    break;
);

if (currentResidual >= lastResidual and ord(loopN) > 3,
    l.l(n) = L_record(n);
    f.l(n) = F_record(n);
    r.l(n) = R_record(n);
    z.l(n) = Z_record(n);
    deflvl.m(n) = deflvl_m_record(n);
    riskprob.l(n) = riskprob_record(n);
    convexCombEqu.m(n) = convexCombEqu_m_record(n);    
    break;
);
display currentResidual;
lastResidual = currentResidual;
L_record(n) = l.l(n);
F_record(n) = f.l(n);
R_record(n) = r.l(n);
Z_record(n) = z.l(n);
deflvl_m_record(n) = deflvl.m(n);
riskprob_record(n) = riskprob.l(n);
convexCombEqu_m_record(n) = convexCombEqu.m(n);
);
display convexCombEqu.m;
* need to negate the convexCombEqu(n) multipliers
*convexCombEqu.m(n) = -convexCombEqu.m(n);
convexCombEqu.m(n) = -convexCombEqu_m_record(n);



* step 2: solve mincostEMPManual with final values 
*         to check if it is solved
embeddedCode reshop:
primalNode: min objPrimal L(n) F(n) R(n) Z(n) objPrimalEqu deflvl(n)
dualNode(n)$(not isLeafNode(n)): max objDual(n) riskProb(child)$(succ(n,child)) objDualEqu(n) convexCombEqu(n)
equ: Nash(primalNode, dualNode(n)$(not isLeafNode(n)))
endEmbeddedCode

$onEcho > reshop.op2
subsolveropt 2
$offEcho

$onEcho > path.op2
crash_method none
$offEcho

mincostEMPManual.optfile = 2;


solve mincostEMPManual using EMP;

scalar t_used;
t_used = timeElapsed;

display t_used;