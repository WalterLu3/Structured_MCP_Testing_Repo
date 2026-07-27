$title This file aims to directly construct equilibrium solution from R-U

$ontext
This experiment is based on the conjecture that given the primal and dual
solutions of R-U, we can potentially construct the equilibrium formulation.
Specifically, the risk probability for node n will be 
(1-lambda) * prob(n) + w(n), where w(n) is the multiplier of the ineqalities
appearing in the R-U formulation, and the multiplier of the dual convex
combination constraint will be t1, which is the artificial variable
appearing in the R-U formulation.
$offtext

* Step 1. solve R-U model
option limrow = 100000;
solve mincost using lp minimizing EC;

loop(n,
    loop(child$succ(n,child),
        riskprob.l(child) = defcost.m(child)/defcost.m(n);
    );
);

scalar checkObj;
    checkObj = sum(n$(not n.first), riskprob.l(n) * (floodCost*f.l(n) + lowCost*z.l(n)));

display riskprob.l, checkObj, defcost.m;



* step 2: solve mincostEMPManual with final values 
*         to check if it is solved

option emp=reshop;

display y.l, v.l;
display riskprob.up, riskProb.l, riskProb.lo, cost.l;

$ontext
* check t1
scalar
    t1_check;
t1_check = cvar_wt - sum(succ('n1',child), cvar_ineq.m('n1',child));

display t1_check;

parameter
    v_check(n)
;
v_check(n)$(not n.first) = prob(n) * cvar_wt/(1-beta) - cvar_ineq.m('n1',n);
display v.l, v_check;

parameter
    c_check(n)
;

c_check(n) = (1-cvar_wt) * prob(n) - defcost.m(n) + cvar_ineq.m('n1',n);

display cost.l, c_check;

parameter
    f_check(n)
;

f_check(n) = floodCost * defcost.m(n) - ldef.m(n);

display f.l, f_check;

parameter
    z_check(n)
;

z_check(n) = lowCost * defcost.m(n) + ldef.m(n);

display z.l, z_check;

parameter
    l_check(n)
;

l_check(n) = -ldef.m(n);

display l.l, l_check, r.l;

parameter
    epsilon_check(n)
;

epsilon_check(n) = - (floodCost * f.l(n) + lowCost * z.l(n));

display epsilon_check, riskprob.up, riskprob.l, riskprob.lo;
$offtext

convexCombEqu.m(n) = -v.l(n);
deflvl.m(n) = ldef.m(n);

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
minor_iter_limit 0
major_iter_limit 0
$offEcho

mincostEMPManual.optfile = 1;

solve mincostEMPManual using EMP;





