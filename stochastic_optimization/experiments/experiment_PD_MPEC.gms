$ontext
Experiment to check if PD solves the problem
$offtext

option emp=reshop;

exactDModel_alternative.holdfixed=1;

set loopN /l1*l%iterationLimit%/;

* step 1 run PD with multiple loops:

loop(loopN,

* solve P
riskProb.fx(n) = riskProb.l(n);


embeddedCode reshop:
primalNode: min objPrimal L(n) F(n) R(n) Z(n) objPrimalEqu deflvl(n)
endEmbeddedCode

solve mincostEMPManualPrimal using EMP;
abort$(mincostEMPManualPrimal.modelstat > 2) "Error: mincostEMPManualPrimal model did not solve";

riskProb.up(n) = (1-cvar_wt) * prob(n) + cvar_wt * prob(n)/(1-beta); 
riskProb.lo(n) = (1-cvar_wt) * prob(n);
riskProb.fx('n1') = 1;

* identify the sign of vi to include in the augmented D step
loop(n$(not sameas(n,'n1')),
* Fixed
    if(abs(f.up(n) - f.lo(n)) < 1e-8,
        f_vi.lo(n) = 0;
        f_vi.up(n) = 0;
* At lower bound
    elseif (abs(f.l(n) - f.lo(n)) < 1e-8),
        f_vi.lo(n) = 0;
        f_vi.up(n) = inf; 
* At upper bound
    elseif (abs(f.l(n) - f.up(n)) < 1e-8),
        f_vi.lo(n) = -inf;
        f_vi.up(n) = 0;     
* Between bounds
    else
        f_vi.lo(n) = -inf;
        f_vi.up(n) = inf;        
    );
);

* variable L
loop(n$(not sameas(n,'n1')),
* Fixed
    if(abs(l.up(n) - l.lo(n)) < 1e-8,
        l_vi.lo(n) = 0;
        l_vi.up(n) = 0;
* At lower bound
    elseif (abs(l.l(n) - l.lo(n)) < 1e-8),
        l_vi.lo(n) = 0;
        l_vi.up(n) = inf; 
* At upper bound
    elseif (abs(l.l(n) - l.up(n)) < 1e-8),
        l_vi.lo(n) = -inf;
        l_vi.up(n) = 0;     
* Between bounds
    else
        l_vi.lo(n) = -inf;
        l_vi.up(n) = inf;        
    );
);

* variable r

loop(n$(not sameas(n,'n1')),
* Fixed
    if(abs(r.up(n) - r.lo(n)) < 1e-8,
        r_vi.lo(n) = 0;
        r_vi.up(n) = 0;
* At lower bound
    elseif (abs(r.l(n) - r.lo(n)) < 1e-8),
        r_vi.lo(n) = 0;
        r_vi.up(n) = inf; 
* At upper bound
    elseif (abs(r.l(n) - r.up(n)) < 1e-8),
        r_vi.lo(n) = -inf;
        r_vi.up(n) = 0;     
* Between bounds
    else
        r_vi.lo(n) = -inf;
        r_vi.up(n) = inf;        
    );
);

* variable z
loop(n$(not sameas(n,'n1')),
* Fixed
    if(abs(z.up(n) - z.lo(n)) < 1e-8,
        z_vi.lo(n) = 0;
        z_vi.up(n) = 0;
* At lower bound
    elseif (abs(z.l(n) - z.lo(n)) < 1e-8),
        z_vi.lo(n) = 0;
        z_vi.up(n) = inf; 
* At upper bound
    elseif (abs(z.l(n) - z.up(n)) < 1e-8),
        z_vi.lo(n) = -inf;
        z_vi.up(n) = 0;     
* Between bounds
    else
        z_vi.lo(n) = -inf;
        z_vi.up(n) = inf;        
    );
);

L.fx(n) = L.l(n);
F.fx(n) = F.l(n);
R.fx(n) = R.l(n);
Z.fx(n) = Z.l(n);

* take dual nlp step
mult_of_deflvl.fx(n) = deflvl.m(n);


solve D_Step_MPEC using mpec minimizing mpecObjVal;
abort$(D_Step_MPEC.modelstat > 2) "Error: D_Step_MPEC model did not solve";


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
);

* need to negate the convexCombEqu(n) multipliers
convexCombEqu.m(n) = rho.m(n);


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
prox_pert 0
crash_pert no
minor_iter_limit 1
major_iter_limit 0
$offEcho

mincostEMPManual.optfile = 1;

solve mincostEMPManual using EMP;