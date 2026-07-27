$ontext
Experiment to create exact equilibrium model
$offtext

option emp=reshop;

solve mincost using lp minimizing EC;

mult_of_deflvl.fx(n) = ldef.m(n);

backwardControlChild(n) = yes;
backwardControlChild('n1') = no;

set
    F_GEQ_ON(n)
    F_LEQ_ON(n)
    Z_GEQ_ON(n)
    Z_LEQ_ON(n)
    L_GEQ_ON(n)
    L_LEQ_ON(n)
    R_GEQ_ON(n)
    R_LEQ_ON(n)
;

F_GEQ_ON(child)$(backwardControlChild(child) and (abs(F.l(child) - F.lo(child)) < 1e-8 or (F.l(child) - F.lo(child) > 1e-8 and F.up(child) - F.l(child) > 1e-8))) = yes;
F_LEQ_ON(child)$(backwardControlChild(child) and (abs(F.l(child) - F.up(child)) < 1e-8 or (F.l(child) - F.lo(child) > 1e-8 and F.up(child) - F.l(child) > 1e-8))) = yes;
L_GEQ_ON(child)$(backwardControlChild(child) and (abs(L.l(child) - L.lo(child)) < 1e-8 or (L.l(child) - L.lo(child) > 1e-8 and L.up(child) - L.l(child) > 1e-8))) = yes;
L_LEQ_ON(child)$(backwardControlChild(child) and (abs(L.l(child) - L.up(child)) < 1e-8 or (L.l(child) - L.lo(child) > 1e-8 and L.up(child) - L.l(child) > 1e-8))) = yes;
R_GEQ_ON(child)$(backwardControlChild(child) and (abs(R.l(child) - R.lo(child)) < 1e-8 or (R.l(child) - R.lo(child) > 1e-8 and R.up(child) - R.l(child) > 1e-8))) = yes;
R_LEQ_ON(child)$(backwardControlChild(child) and (abs(R.l(child) - R.up(child)) < 1e-8 or (R.l(child) - R.lo(child) > 1e-8 and R.up(child) - R.l(child) > 1e-8))) = yes;
Z_GEQ_ON(child)$(backwardControlChild(child) and (abs(Z.l(child) - Z.lo(child)) < 1e-8 or (Z.l(child) - Z.lo(child) > 1e-8 and Z.up(child) - Z.l(child) > 1e-8))) = yes;
Z_LEQ_ON(child)$(backwardControlChild(child) and (abs(Z.l(child) - Z.up(child)) < 1e-8 or (Z.l(child) - Z.lo(child) > 1e-8 and Z.up(child) - Z.l(child) > 1e-8))) = yes;

model exactDModel / objDualEqu
                    convexCombEqu
                    FOONC_F_GEQ
                    FOONC_F_LEQ
                    FOONC_Z_GEQ
                    FOONC_Z_LEQ
                    FOONC_L_GEQ
                    FOONC_L_LEQ
                    FOONC_R_GEQ
                    FOONC_R_LEQ
/;

embeddedCode reshop:
dualNode(n)$(not isLeafNode(n)): max objDual(n) riskProb(child)$(succ(n,child)) objDualEqu(n) convexCombEqu(n)
F_GEQ_NODE(child)$(F_GEQ_ON(child)): vi FOONC_F_GEQ(child) f_geq(child)
F_LEQ_NODE(child)$(F_LEQ_ON(child)): vi FOONC_F_LEQ(child) f_leq(child)
L_GEQ_NODE(child)$(L_GEQ_ON(child)): vi FOONC_L_GEQ(child) l_geq(child)
L_LEQ_NODE(child)$(L_LEQ_ON(child)): vi FOONC_L_LEQ(child) l_leq(child)
R_GEQ_NODE(child)$(R_GEQ_ON(child)): vi FOONC_R_GEQ(child) r_geq(child)
R_LEQ_NODE(child)$(R_LEQ_ON(child)): vi FOONC_R_LEQ(child) r_leq(child)
Z_GEQ_NODE(child)$(Z_GEQ_ON(child)): vi FOONC_Z_GEQ(child) z_geq(child)
Z_LEQ_NODE(child)$(Z_LEQ_ON(child)): vi FOONC_Z_LEQ(child) z_leq(child)
endEmbeddedCode

option emp=reshop;

solve exactDModel using emp;

$exit



