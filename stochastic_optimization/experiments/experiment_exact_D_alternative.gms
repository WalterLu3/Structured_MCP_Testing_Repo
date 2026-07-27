$ontext
Experiment to create exact equilibrium model
$offtext

option limrow=1000;

option emp=reshop;

solve mincost using lp minimizing EC;


mult_of_deflvl.fx(n) = ldef.m(n);

* here, we control the complementary sign (>=, =, <=) by 
* controlling the complement variables 

* variable f
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


exactDModel_alternative.holdfixed=1;

$ontext
embeddedCode reshop:
riskOptNode: max objDualComp_nlp riskprob(n) objDualEquComp_nlp convexCombEquAlternative_nlp
f_lcons(n)$(not sameas(n,'n1')): vi FOONC_F_VI(n) f_vi(n)
l_lcons(n)$(not sameas(n,'n1')): vi FOONC_L_VI(n) l_vi(n)
r_lcons(n)$(not sameas(n,'n1')): vi FOONC_R_VI(n) r_vi(n)
z_lcons(n)$(not sameas(n,'n1')): vi FOONC_Z_VI(n) z_vi(n)
equNode: Nash(riskOptNode, f_lcons(n)$(not sameas(n,'n1')), l_lcons(n)$(not sameas(n,'n1')), r_lcons(n)$(not sameas(n,'n1')), z_lcons(n)$(not sameas(n,'n1')))
endEmbeddedCode

option emp=reshop;

solve exactDModel_alternative using emp;
display mult_of_deflvl.l;
$offtext

solve D_Step_MPEC using mcp;


* convexCombEqu.m(n) = -convexCombEquAlternative_nlp.m(n);
convexCombEqu.m(n) = rho.l(n);
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
minor_iter_limit 1
major_iter_limit 0
$offEcho

mincostEMPManual.optfile = 1;

solve mincostEMPManual using EMP;




display nodePath;