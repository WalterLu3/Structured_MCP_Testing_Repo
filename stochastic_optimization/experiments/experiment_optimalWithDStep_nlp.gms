$TITLE Take a D step from a primal optimal solutions with nlp formulation

option emp=reshop;

* step 1. solve RU formulation to get primal optimal



 solve mincost using LP minimizing EC;

* embeddedCode reshop:
* primalNode: min objPrimal L(n) F(n) R(n) Z(n) objPrimalEqu deflvl(n)
* dualNode(n)$(not isLeafNode(n)): max objDual(n) riskProb(child)$(succ(n,child)) objDualEqu(n) convexCombEqu(n)
* equ: Nash(primalNode, dualNode(n)$(not isLeafNode(n)))
* endEmbeddedCode

* solve mincostEMPManual using EMP;

parameter
    answer_riskprob(n)
    answer_rho(n)
;

answer_riskprob(n) = riskprob.l(n);

* Step 2. Given primal optimal solution and primal 
*         constraint multiplier, take an extra step.

* take dual nlp step
mult_of_deflvl.fx(n) = ldef.m(n);

solve dualNLP using nlp maximizing objDualComp_nlp;


* Feed the solution back to the equilibrium model
* remember to flip the sign of convex comb constraint

convexCombEqu.m(n) = -convexCombEquAlternative_nlp.m(n);
deflvl.m(n) = mult_of_deflvl.l(n);

* step 3: solve mincostEMPManual with final values 
*         to check if it is solved

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


embeddedCode reshop:
primalNode: min objPrimal L(n) F(n) R(n) Z(n) objPrimalEqu deflvl(n)
dualNode(n)$(not isLeafNode(n)): max objDual(n) riskProb(child)$(succ(n,child)) objDualEqu(n) convexCombEqu(n)
equ: Nash(primalNode, dualNode(n)$(not isLeafNode(n)))
endEmbeddedCode

mincostEMPManual.optfile = 1;

solve mincostEMPManual using EMP;

parameter
    diff_riskprob(n)
    diff_rho(n)
;

diff_riskprob(n) = answer_riskprob(n) - riskProb.l(n);

* Step 4. solve an lp minimizing 0 to find a feasible solution
*         for rho and see if fixing rho allows us to solve the
*         problem

solve findRho using lp maximizing dummyObj;

convexCombEqu.m(n) = rho.l(n);

embeddedCode reshop:
primalNode: min objPrimal L(n) F(n) R(n) Z(n) objPrimalEqu deflvl(n)
dualNode(n)$(not isLeafNode(n)): max objDual(n) riskProb(child)$(succ(n,child)) objDualEqu(n) convexCombEqu(n)
equ: Nash(primalNode, dualNode(n)$(not isLeafNode(n)))
endEmbeddedCode

mincostEMPManual.optfile = 1;

solve mincostEMPManual using EMP;


