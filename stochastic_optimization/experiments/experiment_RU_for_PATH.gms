option emp=reshop;
* solve ru formulation
solve mincost using nlp minimizing EC;

loop(n,
    loop(child$succ(n,child),
        riskprob.l(child) = defcost.m(child)/defcost.m(n);
    );
);

* Note that we have to flip the sign of convex combination due to the max
convexCombEqu.m(n) = -v.l(n);

deflvl.m(n) = ldef.m(n);
*

* step 2: solve mincostEMPManual with final values 
*         to check if it is solved
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
$offEcho

mincostEMPManual.optfile = 1;




solve mincostEMPManual using EMP;

display mincostEMPManual.modelstat;


scalar t_used;
t_used = timeElapsed;

display t_used;