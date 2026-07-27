$ontext
Experiment to check if PD (alternative LP) solves the problem
$offtext

option emp=reshop;

set 
   loopN /l1*l%iterationLimit%/;

*******************************************
* Step 2: Solve D with alternative LP given primal optimal
*******************************************

* solve R-U form to get primal optimals
*solve mincost using lp minimizing EC;

embeddedCode reshop:
primalNode: min objPrimal L(n) F(n) R(n) Z(n) objPrimalEqu deflvl(n)
dualNode(n)$(not isLeafNode(n)): max objDual(n) riskProb(child)$(succ(n,child)) objDualEqu(n) convexCombEqu(n)
equ: Nash(primalNode, dualNode(n)$(not isLeafNode(n)))
endEmbeddedCode

solve mincostEMPManual using EMP;

parameter 
rho(n);
* fix multipliers based on primal optimals
mult_of_deflvl.fx(n) = deflvl.m(n);

* take an alternative D step (i.e. we solve the alternative LP
*                                  recursively from the bottom up)

* Due to how we order nodes, we can implement backward recursion by
* looping nonleaf nodes from last to first

loop(nn1,
   loop(nn2$((ord(nn2) = card(n) - ord(nn1) + 1) and not isLeafNode(nn2)),
* activate correct lp
      backwardControl(n) = no;
      backwardControlChild(n) = no;
      backwardControl(nn2) = yes;
      backwardControlChild(n)$(succ(nn2,n)) = yes;

      solve originalDual using LP maximizing objDualComp;
*      solve alternativeDual using LP maximizing objDualComp;
   );
);


* set the correct convex combination constraint multipliers
convexCombEqu.m(n) = -convexCombEquAlternative.m(n);

*****************************************
* step 3: solve mincostEMPManual with final 
*         values to check if it is solved
*****************************************

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

