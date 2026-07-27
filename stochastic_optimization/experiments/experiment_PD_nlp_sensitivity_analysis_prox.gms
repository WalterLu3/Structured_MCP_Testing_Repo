$ontext
Experiment to check if PD_alternative with Primal problem added proximal term is nicely solved
$offtext

* main parameter
* 1. ppterm:  controls the objective of primal in the form of -- min obj + ppterm ||x - x^*||^2

* Things done
* 1. solve for equilibirum solution for x^*
* 1. add a primal prox at x^* to primalthe end (pptermSquare)
* 2. add a primal prox term at x^* of dual at the end (pptermSquare)
* 3. D_alternative add terms related to proximal term

option emp=reshop;

* calculate primal optimal
pptermProx = 0;

embeddedCode reshop:
primalNode: min objPrimal L(n) F(n) R(n) Z(n) objPrimalEqu deflvl(n)
dualNode(n)$(not isLeafNode(n)): max objDual(n) riskProb(child)$(succ(n,child)) objDualEqu(n) convexCombEqu(n)
equ: Nash(primalNode, dualNode(n)$(not isLeafNode(n)))
endEmbeddedCode

solve mincostEMPManual using EMP;


* these are used as x^* in the model
F_record(n) = F.l(n);
L_record(n) = L.l(n);
R_record(n) = R.l(n);
Z_record(n) = Z.l(n);

* add ppterm * || x - x^* ||^2 to objective
pptermProx = %ppterm%;

set loopN /l1*l%iterationLimit%/;
parameter 
    KKTViolation(loopN)
    objectiveRecord(loopN)
    solDiff(loopN)
    riskProbDiff(loopN)
    fflag(n,loopN)
    lflag(n,loopN)
    rflag(n,loopN)
    zflag(n,loopN)
    deflvlflag(n,loopN)
    squareTerm(loopN)
;

* step 1 run PD with multiple loops:

riskprob.l(n) = prob(n);


scalar loopCount /0/;

L.l(n)$(not n.first) = 0;
F.l(n) = 0;
R.l(n) = 0;
Z.l(n) = 0;

F_record(n) = F.l(n);
L_record(n) = L.l(n);
R_record(n) = R.l(n);
Z_record(n) = Z.l(n);

riskprob_record(n) = riskprob.l(n);


scalar
    recordpterm /0/
;

loop(loopN,

loopCount  = loopCount + 1;
* solve P
riskProb.fx(n) = riskProb.l(n);

embeddedCode reshop:
primalNode: min objPrimal L(n) F(n) R(n) Z(n) objPrimalEqu deflvl(n)
endEmbeddedCode

solve mincostEMPManualPrimal using EMP;
*abort$(mincostEMPManualPrimal.modelstat > 2) "Error: mincostEMPManualPrimal model did not solve";

* algo
* F_record(n) = F.l(n);
* L_record(n) = L.l(n);
* R_record(n) = R.l(n);
* Z_record(n) = Z.l(n);

riskProb.up(n) = (1-cvar_wt) * prob(n) + cvar_wt * prob(n)/(1-beta); 
riskProb.lo(n) = (1-cvar_wt) * prob(n);
riskProb.fx('n1') = 1;


* take dual nlp step
mult_of_deflvl.fx(n) = deflvl.m(n);

option nlp=conopt;
solve dualNLP using nlp maximizing objDualComp_nlp;
*abort$(dualNLP.modelstat > 2) "Error: dualNLP model did not solve";

squareTerm(loopN) = sum(n,
                sqr(F.l(n) -  F_record(n)) + 
                sqr(L.l(n) -  L_record(n)) + 
                sqr(R.l(n) -  R_record(n)) + 
                sqr(Z.l(n) -  Z_record(n)) 
              );

fflag(n,loopN) = F.l(n);
lflag(n,loopN) = L.l(n);
rflag(n,loopN) = R.l(n);
zflag(n,loopN) = Z.l(n);
deflvlflag(n,loopN) = deflvl.m(n);

KKTViolation(loopN) = sum(n,
                           f_geq_penalty.l(n) * f_geq_penalty.l(n) +
                           f_leq_penalty.l(n) * f_leq_penalty.l(n) +
                           l_geq_penalty.l(n) * l_geq_penalty.l(n) +
                           l_leq_penalty.l(n) * l_leq_penalty.l(n) +
                           r_geq_penalty.l(n) * r_geq_penalty.l(n) +
                           r_leq_penalty.l(n) * r_leq_penalty.l(n) +
                           z_geq_penalty.l(n) * z_geq_penalty.l(n) +
                           z_leq_penalty.l(n) * z_leq_penalty.l(n) 
                        );

if (KKTViolation(loopN) >= KKTViolation(loopN - 1),
    pTerm = pTerm * 1.2;
);

objectiveRecord(loopN) = sum(n$(not n.first), prod(nn$(nodePath(n,nn)), riskProb.l(nn)) * ccostl(n))
                         + squareTerm(loopN);
*objectiveRecord(loopN) = objPrimal.l;


solDiff(loopN) = sum(n,
            abs(f.l(n) - F_record(n)) + 
            abs(l.l(n) - L_record(n)) + 
            abs(r.l(n) - R_record(n)) + 
            abs(z.l(n) - Z_record(n))  
          );

riskProbDiff(loopN) = sum(n, abs(riskprob.l(n) - riskprob_record(n)));


F_record(n) = F.l(n);
L_record(n) = L.l(n);
R_record(n) = R.l(n);
Z_record(n) = Z.l(n);
riskprob_record(n) = riskprob.l(n);

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

* now, try to find the correct multiplier
solve findRho using nlp minimizing dummyObj;


* if we find a solution of the multiplier, put it in the full model
if (findRho.modelstat < 2,
* check if solved
convexCombEqu.m(n) = rho.l(n);
    else
    convexCombEqu.m(n) = -convexCombEquAlternative_nlp.m(n);
);


* solve mincostEMPManual with final values 
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

* if it is solved ( i.e. modelstat < 3 ), break the loop
if(mincostEMPManual.modelstat < 3,
    break;
);


);

scalar re
       reDeflvl;

re = sum(n, abs(fflag(n,'l1') - fflag(n,'l3'))
           +abs(lflag(n,'l1') - lflag(n,'l3'))
           +abs(rflag(n,'l1') - rflag(n,'l3'))
           +abs(zflag(n,'l1') - zflag(n,'l3')));

reDeflvl = sum(n, abs(deflvlflag(n,'l1') - deflvlflag(n,'l3')));

display re;
display reDeflvl;
display solDiff;
display riskProbDiff;
display KKTViolation;
display objectiveRecord;
display squareTerm;
display mincostEMPManual.objval;
display loopCount;
display  mincostEMPManual.modelstat;

* if(mincostEMPManual.modelstat > 2,
*     abort$(1 > 0) "Error: whole problem not solved";
* );


* display FOONC_F_GEQ_nlp.m, FOONC_F_LEQ_nlp.m, FOONC_L_GEQ_nlp.m, FOONC_L_LEQ_nlp.m, FOONC_R_GEQ_nlp.m, FOONC_R_LEQ_nlp.m, FOONC_Z_GEQ_nlp.m, FOONC_Z_LEQ_nlp.m;
* display nodePath;
* $exit


* need to negate the convexCombEqu(n) multipliers and rescale 
*convexCombEqu.m(n) = -convexCombEquAlternative_nlp.m(n);
*convexCombEqu.m(n) = -convexCombEquAlternative_nlp.m(n) * prod(child$(nodePath(n,child) and not sameas(n,child)), riskProb.l(child));

$exit
solve findRho using nlp minimizing dummyObj;
convexCombEqu.m(n) = rho.l(n);

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

display objprimal.l;



