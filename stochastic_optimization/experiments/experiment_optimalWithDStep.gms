$TITLE Take a D step from a primal optimal solutions 

option emp=reshop;

* step 1. solve RU formulation to get primal optimal

* solve mincost using LP minimizing EC;

embeddedCode reshop:
primalNode: min objPrimal L(n) F(n) R(n) Z(n) objPrimalEqu deflvl(n)
dualNode(n)$(not isLeafNode(n)): max objDual(n) riskProb(child)$(succ(n,child)) objDualEqu(n) convexCombEqu(n)
equ: Nash(primalNode, dualNode(n)$(not isLeafNode(n)))
endEmbeddedCode

solve mincostEMPManual using EMP;

parameter
    answer_riskprob(n)
    answer_rho(n)
;

answer_riskprob(n) = riskprob.l(n);
answer_rho(n) = convexCombEqu.m(n);

* intentionally mess up risk probability

* riskprob.l(n) = prob(n);
* riskProb.fx('n1') = 1;
* convexCombEqu.m(n) = 0;


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
* If the original model solved is the equilibirum one.
mult_of_deflvl.fx(n) = deflvl.m(n);

* ELSE If the original model solved is the LP one
* mult_of_deflvl.fx(n) = ldef.m(n);

** Version 2 : Recursive Backward solve


set right(n,n);

right('n38',nn2)$(succ('n38',nn2)) = yes;
display right;

* display right;

* set f_leq_on(n)
*     f_geq_on(n)
*     leqtest1(n)
*     leqtest2(n)
*     leqtest3(n)
* ;

* f_geq_on(child) =  (abs(F.l(child) - F.lo(child)) < 1e-5 or (F.l(child) - F.lo(child) > 1e-5 and F.up(child) - F.l(child) > 1e-5));
* f_leq_on(child) =  (abs(F.l(child) - F.up(child)) < 1e-5 or (F.l(child) - F.lo(child) > 1e-5 and F.up(child) - F.l(child) > 1e-5));

* leqtest1(child)$(abs(F.l(child) - F.up(child)) < 1e-5) = yes;
* leqtest2(child)$(F.l(child) - F.lo(child) > 1e-5) = yes;
* leqtest3(child)$(F.up(child) - F.l(child) > 1e-5) = yes;

* display f_geq_on, f_leq_on, f.lo, f.l, f.up, leqtest1, leqtest2, leqtest3;

set loopn /l1*l%iterationLimit%/;

loop(loopn,
loop(nn1,
   loop(nn2$((ord(nn2) = card(n) - ord(nn1) + 1) and not isLeafNode(nn2)),
* activate correct lp
      backwardControl(n) = no;
      backwardControlChild(n) = no;
      backwardControl(nn2) = yes;
      backwardControlChild(n)$(succ(nn2,n)) = yes;

*   solve originalDual using LP maximizing objDualComp;
*   abort$(originalDual.modelstat <> 1) "Something wrong with original dual";
    
  solve alternativeDual using LP maximizing objDualComp;
  abort$(alternativeDual.modelstat <> 1) "Something wrong with alternative dual";
   );
);
);

* remember to flip the sign of convex comb

convexCombEqu.m(n) = -convexCombEquAlternative.m(n);
* deflvl.m(n) = mult_of_deflvl.l(n);

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

mincostEMPManual.optfile = 1;

solve mincostEMPManual using EMP;

parameter
    diff_riskprob(n)
    diff_rho(n)
;

diff_riskprob(n) = answer_riskprob(n) - riskProb.l(n);
diff_rho(n) = answer_rho(n) - convexCombEqu.m(n)

display diff_riskprob, diff_rho;
$exit
