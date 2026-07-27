$TITLE Take a D step from a primal optimal solutions 

option emp=reshop;

parameter
   answer_riskprob(n)
   answer_rho(n)
;
* step 1. solve RU formulation to get primal optimal

* solve mincost using LP minimizing EC;

embeddedCode reshop:
primalNode: min objPrimal L(n) F(n) R(n) Z(n) objPrimalEqu deflvl(n)
dualNode(n)$(not isLeafNode(n)): max objDual(n) riskProb(child)$(succ(n,child)) objDualEqu(n) convexCombEqu(n)
equ: Nash(primalNode, dualNode(n)$(not isLeafNode(n)))
endEmbeddedCode

solve mincostEMPManual using EMP;



** fix the primal optimal solution
L.fx(n) = L.l(n);
F.fx(n) = F.l(n);
R.fx(n) = R.l(n);
Z.fx(n) = Z.l(n);

riskprob.l(n) = prob(n);
riskProb.fx('n1') = 1;
convexCombEqu.m(n) = 0;


* Take a D step

** Version 1 : manual EMP formulation
$ontext
embeddedCode reshop:
dualNode(n)$(not isLeafNode(n)): max objDual(n) riskProb(child)$(succ(n,child)) objDualEqu(n) convexCombEqu(n)
equ: Nash(dualNode(n)$(not isLeafNode(n)))
endEmbeddedCode

solve mincostEMPManualDual using EMP;

* remember to flip the sign of convex comb

convexCombEqu.m(n) = -convexCombEqu.m(n);
$offtext
** Version 2 : Recursive Backward solve

mult_of_deflvl.l(n) = deflvl.m(n);

loop(nn1,
   loop(nn2$((ord(nn2) = card(n) - ord(nn1) + 1) and not isLeafNode(nn2)),
* activate correct lp
      backwardControl(n) = no;
      backwardControlChild(n) = no;
      backwardControl(nn2) = yes;
      backwardControlChild(n)$(succ(nn2,n)) = yes;

*   solve originalDual using LP maximizing objDualComp;
    solve alternativeDual using LP maximizing objDualComp;
    abort$(alternativeDual.modelstat <> 1) "Error: mincostEMP solution is not feasible";
   );
);
$exit
answer_riskprob(n) = riskProb.l(n);
answer_rho(n) = convexCombEqu.m(n);

* remember to flip the sign of convex comb

convexCombEqu.m(n) = -convexCombEquAlternative.m(n);

* step 2: solve mincostEMPManual with final values 
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



solve mincostEMPManual using EMP;

display riskprob.l, answer_riskprob, convexCombEqu.m, answer_rho;