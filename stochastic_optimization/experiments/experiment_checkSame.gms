$ontext
Experiment to check equilibrium implementation has optimal solution
$offtext

scalar correctObj;

* step 1: solve R-U form to get correct objective value

solve mincost using lp minimizing EC;
correctObj = EC.l;
abort$(mincost.modelstat <> 1) "Error: mincost model did not solve optimally";


* step 2: solve mincost by fixing variables to values from mincostEMP
option emp = reshop;

embeddedCode reshop:
primalNode: min objPrimal L(n) F(n) R(n) Z(n) objPrimalEqu deflvl(n)
dualNode(n)$(not isLeafNode(n)): max objDual(n) riskProb(child)$(succ(n,child)) objDualEqu(n) convexCombEqu(n)
equ: Nash(primalNode, dualNode(n)$(not isLeafNode(n)))
endEmbeddedCode


solve mincostEMPManual using emp;
abort$(mincostEMPManual.modelstat > 2) "Error: mincostEMP model did not solve";


f.fx(n) = f.l(n);
z.fx(n) = z.l(n);
l.fx(n) = l.l(n);
r.fx(n) = r.l(n);

solve mincost using lp minimizing EC;
abort$(mincost.modelstat <> 1) "Error: mincostEMP solution is not feasible";



abort$(abs(objPrimal.l - correctObj) > 1e-3) "Error: mincostEMP objective does not match mincost objective";


* step 3 check if the solutions of R-U and equilibrium formulations are the same
parameter
    f_record(n)
    z_record(n)
    l_record(n)
    r_record(n)
;

scalar
    solutionDifference /0/
;

f_record(n) = f.l(n);
z_record(n) = z.l(n);
l_record(n) = l.l(n);
r_record(n) = r.l(n);

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

solve mincost using lp minimizing EC;

loop(n,
    solutionDifference = solutionDifference + abs(f_record(n) - f.l(n));
    solutionDifference = solutionDifference + abs(z_record(n) - z.l(n));
    solutionDifference = solutionDifference + abs(l_record(n) - l.l(n));
    solutionDifference = solutionDifference + abs(r_record(n) - r.l(n));
);

display solutionDifference;

if (solutionDifference > 1e-5,
   put_utility 'log' / 'RESIDUAL=' solutionDifference:0:6;
);