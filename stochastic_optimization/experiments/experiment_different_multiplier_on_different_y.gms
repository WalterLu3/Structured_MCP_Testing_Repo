$ontext
This file investigate if we can find multiple solutions of a equilibrium problem

Idea: Given a non-extreme point solution for clearLake with equilibrium form,
we a node whose (at least) 2 children leaf node having  lb_a < riskProb(a) < ub_a
                                                        lb_b < riskProb(b) < ub_b

Then, we know that lb_a < riskProb(a) + epsilon < ub_a
                   lb_b < riskProb(b) - epsilon < ub_b
is also an optimal solution for the dual risk problems (risk variables + multiplier).

Then, since we have optimal primal solution, risk variables + multiplier, the 
remaining question is whether we can find the multiplier for solving the equilibrium
system.
$offtext

* Step 1: Solve for the equilibrium formulation
option emp=reshop;

embeddedCode reshop:
primalNode: min objPrimal L(n) F(n) R(n) Z(n) objPrimalEqu deflvl(n)
dualNode(n)$(not isLeafNode(n)): max objDual(n) riskProb(child)$(succ(n,child)) objDualEqu(n) convexCombEqu(n)
equ: Nash(primalNode, dualNode(n)$(not isLeafNode(n)))
endEmbeddedCode


solve mincostEMPManual using EMP;

parameter recordDeflvl(n);
recordDeflvl(n) = deflvl.m(n);
* Step 2. check for non-extreme point solution

scalar boundCount /0/
       nonExtremePoint /0/;

set nonExtremeNodes(n);

nonExtremeNodes(n) = no;
loop(n$(not isLeafNode(n)),
   boundCount = 0;

   loop(child$succ(n,child),
      if (abs(riskProb.l(child) - riskProb.lo(child)) < 1e-5 or (abs(riskProb.l(child) - riskProb.up(child)) < 1e-5),
         boundCount = boundCount + 1;
      );
   );

   if (boundCount < %nchildren% - 1,
      nonExtremePoint = nonExtremePoint + 1;
      nonExtremeNodes(n) = yes;
   );
);

display nonExtremePoint,nonExtremeNodes, succ;
display nonExtremePoint;



backwardControlChild(child) = yes;
backwardControlChild('n1') = no;

riskProb.l('n35') = riskProb.l('n35') - 0.01;
riskProb.l('n36') = riskProb.l('n36') + 0.01;



* solve findPrimalMultipliers using lp minimizing dummyObj ;


* deflvl.m(n) = mult_of_deflvl.l(n);

convexCombEqu.m(n) = -convexCombEqu.m(n);


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

* display mult_of_deflvl.l;
* display deflvl.m;

* scalar residual /0/;
* loop(n$(not n.first),
*     residual = residual + abs(mult_of_deflvl.l(n) - deflvl.m(n));
* );
* display residual;


* display mult_of_deflvl.l,recordDeflvl;