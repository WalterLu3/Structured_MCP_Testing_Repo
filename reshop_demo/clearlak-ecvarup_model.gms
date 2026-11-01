$TITLE risk-averse test with artificial trees

$ontext
The model is based on the ClearLake example. The model is parametric in the number of
stages


Reference: Exercise, p. 44 in
Birge, R, and Louveaux, F V, Introduction to Stochastic Programming.
Springer, 1997.

The original model on which this is based on is from: Olivier Huber <oli.huber@gmail.com>.
See clearlak-ecvarup.gms for the original model.

Contributor: Cheng-Wei Lu  <s10130134@gmail.com>
Date:        Jan 2026
$offtext

$ontext
This model file has several models:
- mincost: the extensive form with CVaR incorporated in the objective function
- mincostEMP: the EMP formulation of the extensive form (recursive definition)
- mincostEMPManual: manual reformulation of the EMP model (primal + dual)
- mincostEMPManualPrimal: manual reformulation of the EMP model (primal only)
- mincostEMPManualDual: manual reformulation of the EMP model (dual only)
$offtext


$eolcom #

$if not set tol $set tol 1e-6

$onEcho > pathnlp.opt
conv_tol 1e-12
crash_method none
prox_pert 0
crash_pert no
$offEcho

* $onEcho > path.opt
* conv_tol 1e-10
* crash_method none
* prox_pert 0
* crash_pert no
* factorization_method conopt
* output_preprocess_level 2
* output_warnings 1
* path_basis_modify_tol 1000000
* path_basis_modify_verbose 1
* minor_iter_limit 1
* major_iter_limit 1
* $offEcho

$onEcho > path.opt
crash_method none
prox_pert 0
crash_pert no
minor_iter_limit 1
major_iter_limit 0
$offEcho

$onEcho > %gams.emp%.opt
subsolveropt 1
$offEcho

$onEcho > %gams.emp%.op2
subsolveropt 0
$offEcho

option optca = 1e-12;

* We need cplex to use a simplex method
* lpmethod 2 fails
$onEcho > cplex.opt
lpmethod 1
$offEcho

$if not set nstage    $eval nstage 5
$if not set nchildren $eval nchildren 3

* init
$eval x '0' $eval i '0' $eval num_nodes '0'

* poor man's implementation of sum(i=1 to %nstage%, num_nodes += power(%nchildren%,%i%))
$label rep $eval num_nodes '%num_nodes% + power(%nchildren%,%i%)' $eval i '%i%+1'

$ifE %i%<%nstage% $goto rep
* TODO why does the following not work:
* $ifE %i% < %nstage% $goto rep

$log Scenario tree stats: stage: %nstage%; nchdilren: %nchildren%; number nodes: %num_nodes%

$macro ccostl(n_temp) \
   (floodCost * F.l(n_temp) + lowCost * Z.l(n_temp))

$macro ccost(n_temp) \
   (floodCost * F(n_temp) + lowCost * Z(n_temp))

SCALAR
   riskWeightError /1/;

SETS p Stochastic realizations (precipitation) /low, normal, high/,
     t Time periods                            /t1*t%nstage%/,
     n set of nodes                            /n1*n%num_nodes%/,
     succ(n,n) Successor relationship,
     list(n)
     nt(n,t) n belongs to time stage t
     a /a1 * a3/;

ALIAS (n,child,parent);

* Define a regular tree with nchildren
succ(n,child)$(ord(child) >= %nchildren%*ord(n)-(%nchildren%-2) AND
               ord(child) <= %nchildren%*ord(n)+1) = yes;

* find the time stage t of a node n

nt(n,t)$(ord(t)=(floor(log((%nchildren% - 1)*(ord(n) - 1) + 1) / log(%nchildren%) + 1e-9) + 1)) = yes;

* succ(n,child) = yes$(ord(child) >= %nchildren%*ord(n)-(%nchildren%-2) AND
*                      ord(child) <= %nchildren%*ord(n)+1);

*-------------------------------------------------------------------------------
*Parameters are specified

PARAMETERS floodCost  'Flooding penalty cost thousand CHF per mm'   /10/,
           lowCost    'Water importation cost thousand CHF per mm'  /5/,
           l_start    'Initial water level (mm)'                    /230/,
           l_max      'Maximum reservoir level (mm)'                /250/,
           r_max      'Maximum normal release in any period'        /200/;

*-----------------------------------------------------------------------------

PARAMETERS prob(n)    'Conditional probability',
           ndelta(n)  'Water inflow at each node'
           ndeltaA(a,n);

SET pp /pp1*pp%nchildren%/;

$ontext
PARAMETERS rain_vals(pp<)
$ifthenE %nchildren%=3 
*/ 1 250, 2 450, 3 550/
*/ 1 50, 2 250, 3 350/
/ 1 -290, 2 250, 3 350/
$elseifE  %nchildren%=4
/ 1 25, 2 100, 3 200, 4 400/
$elseifE  %nchildren%=5
/ 1 15, 2 75, 3 150, 4 300, 5 450/
$endif
;
$offtext

PARAMETERS rain_vals(pp);

execseed = %randomSeed%;

************** important ***************
* generate random rainfall values if the children nubmer is 3;

rain_vals(pp) = uniform(-100,400);

ALIAS(n,nn);
list(n) = yes$n.first;


prob(n)$(NOT n.first) = binomial(%nchildren%-1, mod(ord(n)+1, %nchildren%)) / power(2,%nchildren%-1);
prob(n)$n.first = 1.;

display prob;

ndelta(n)$(NOT n.first) = sum{pp$(pp.pos = 1+mod(ord(n)+1, %nchildren% )), rain_vals(pp)};

ndeltaA(a,n)$(NOT n.first) = sum{pp$(pp.pos = 1+mod(ord(n)+1, %nchildren% )), rain_vals(pp)};

display ndelta;

* execute_unload 'clearlaktree-like-scenario-tree.gdx' n, succ, prob;


VARIABLE EC               'Total Cost';

*------------------------------------------------------------------------------
* Model logic:  only needs n, succ, prob, ndelta
*------------------------------------------------------------------------------

POSITIVE VARIABLES
		   F(n)             'Floodwater released (mm)',
         L(n)             'Reservoir water level -- EOP',
		   R(n)             'Normal release of water (mm)',
		   Z(n)             'Water imports (mm)';

R.up(n) = r_max;
L.up(n) = l_max;
L.fx(n)$(n.first) = l_start;

* CVaR parameters
PARAMETER tail    'tail of the CVaR',
          cvar_wt 'weight of the CVaR';

PARAMETER beta;

SET test1, test2;

PARAMETERS tails(test1<)    / '1'   1., '0.75' .75, '0.5' .5, '0.3' .3, '0.1' .1/;
PARAMETERS cvar_wts(test2<) / '0.9' .9, '0.75' .75, '0.5' .5, '0.3' .3, '0.1' .1/;

* Comparison
PARAMETERS L_L(n), L_M(n), ldef_M(n), F_L(n), F_M(n), R_L(n), R_M(n), Z_L(n), Z_M(n),
           L_Ld(n), F_Ld(n), R_Ld(n), Z_Ld(n), y_L(n), cost_L(n), v_L(n);

VARIABLES          v(n)    'Var value at each non-leaf node',
                   cost(n) 'total cost at each node';

POSITIVE VARIABLES y(n)    'Contribution of the cost for each node'

*-------------------------------------------------------------------------------
* Model components for computing CVaR a posteriori
*-------------------------------------------------------------------------------

VARIABLES cvarURobj;
EQUATIONS defcvarURobj, cvarURcons(n,n);

PARAMETER QL(n);

SINGLETON SET activeNode(n);

defcvarURobj..
   cvarURobj
   =E=
   sum(activeNode(n), v(n) + [1/(1-beta)] * sum(succ(n,child), prob(child)*y(child)));

cvarURcons(n,child)$(activeNode(n) AND succ(n,child))..
   y(child) =G= QL(child) - v(n);

MODEL cvarUR 'Uryasev-Rockafellar formulation for cvar' / defcvarURobj, cvarURcons /;

PARAMETER QLd(n), y_Ld(n), v_ld(n);

*-------------------------------------------------------------------------------
* Reference model
*-------------------------------------------------------------------------------
parameter
   pert /%pert%/
;

EQUATIONS ecdef, ldef; 

EQUATIONS cvar_ineq(n,n), defcost(n), totalCost;

cvar_ineq(n,child)$(succ(n,child))..
   y(child) =G= cost(child) - v(n);

defcost(n)..
   cost(n) =G= (floodcost*F(n)+lowCost*Z(n) + (pert * (sqr(F(n)) + sqr(Z(n)))))$(NOT n.first) + 
   (
          cvar_wt * [ v(n) + [1/(1-beta)] * sum(succ(n,child), prob(child)*y(child)) ] +
      (1-cvar_wt) * [ sum(succ(n,child), prob(child)*cost(child)) ]
   )$(sum(succ(n,child), yes));

totalCost..
   EC =E= sum(n$n.first, cost(n));


ldef(n)$[NOT n.first].. L(n) =e= sum{ succ(parent,n), L(parent)} + ndelta(n)+Z(n)-R(n)-F(n);

MODEL mincost / totalCost, defcost, cvar_ineq, ldef /;

mincost.optfile=1;

*-------------------------------------------------------------------------------
* Reference model -- multiAgent version
*-------------------------------------------------------------------------------


EQUATIONS ldefA(a,n); 

EQUATIONS cvar_ineqA(a,n,n), defcostA(a,n), totalCostA(a);

VARIABLES          vA(a,n)    'Var value at each non-leaf node',
                   costA(a,n) 'total cost at each node'
                   ECA(a);

POSITIVE VARIABLES yA(a,n)    'Contribution of the cost for each node';

POSITIVE VARIABLES
		   FA(a,n)             'Floodwater released (mm)',
         LA(a,n)             'Reservoir water level -- EOP',
		   RA(a,n)             'Normal release of water (mm)',
		   ZA(a,n)             'Water imports (mm)';

RA.up(a,n) = r_max;
LA.up(a,n) = l_max;
LA.fx(a,n)$(n.first) = l_start;

cvar_ineqA(a,n,child)$(succ(n,child))..
   yA(a,child) =G= costA(a,child) - vA(a,n);

defcostA(a,n)..
   costA(a,n) =G= (floodcost*FA(a,n)+lowCost*ZA(a,n))$(NOT n.first) + 
   (
          cvar_wt * [ vA(a,n) + [1/(1-beta)] * sum(succ(n,child), prob(child)*yA(a,child)) ] +
      (1-cvar_wt) * [ sum(succ(n,child), prob(child)*costA(a,child)) ]
   )$(sum(succ(n,child), yes));

totalCostA(a)..
   ECA(a) =E= sum(n$n.first, costA(a,n));


ldefA(a,n)$[NOT n.first].. LA(a,n) =e= sum{ succ(parent,n), LA(a,parent)} + ndeltaA(a,n)+ZA(a,n)-RA(a,n)-FA(a,n);

MODEL mincostA / totalCostA, defcostA, cvar_ineqA, ldefA /;



*-------------------------------------------------------------------------------
* EMP model
*-------------------------------------------------------------------------------

VARIABLES  objnode(n)     'nodal (local) cost'; 

EQUATIONS  defobjnode(n)  'nodal cost definition',
           deflvl(n)      'water level';

defobjnode(n)..
      objnode(n) =E= (floodCost*F(n)+lowCost*Z(n))$(not n.first);

deflvl(n).. L(n) =E= sum( succ(parent,n), L(parent) ) + ndelta(n)+Z(n)-R(n)-F(n);

MODEL mincostEMP 'EMP stochastic model' / defobjnode, deflvl /;

*mincostEMP.optfile = 1;


SCALAR optfileVal / 1 /;

tail = .4;
cvar_wt = .3;

if( %gams.optfile% > 1, optfileVal = %gams.optfile% );

display tail, cvar_wt;

beta = 1-tail;

mincost.optfile = optfileVal;



*-------------------------------------------------------------------------------
* Equilibrium formulation
*-------------------------------------------------------------------------------

set
   nodePath(n,nn) 'nn is in path from root to node n'
   isLeafNode(n) 'indicator for leaf nodes';

alias(n, nn1, nn2);
display n;

nodePath(nn1,nn2) = no;

loop(n,
   nodePath(n,nn1) = sum(succ(parent,n), nodePath(parent,nn1));
   nodePath(n,n) = yes;
);

* so right now  sum(nodePath(n,n1), riskProb(n1)); will be the product
* of risk adjusted probabilites for node n

* leaf: just initialize local costs
isLeafNode(n)$(NOT sum(succ(n,child), yes)) = yes;

********
* Primal Problem
********
free variable
   objPrimal
   objDual(n)
;

equation
   objPrimalEqu
   objDualEqu(n)
   convexCombEqu(n)
;

positive variable
   riskProb(n)
;

parameters
   F_record(n)
   L_record(n)
   R_record(n)
   Z_record(n)
   riskprob_record(n)
;

F_record(n) = 0;
L_record(n) = 0;
R_record(n) = 0;
Z_record(n) = 0;
riskprob_record(n) = prob(n);

scalar
   pptermSquare /0/
   pptermProx /0/
;

objPrimalEqu..
   objPrimal =e= sum(n$(NOT n.first), prod(nodePath(n,nn1), riskProb(nn1)) * (floodCost*F(n) + lowCost*Z(n)
                                                                              + pptermSquare *(sqr(f(n)) + 
                                                                                               sqr(l(n)) + 
                                                                                               sqr(r(n)) + 
                                                                                               sqr(z(n)))
                                                                             ))
*   + pptermSquare * sum(n$(NOT n.first), sqr(f(n)) + 
*                                   sqr(l(n)) + 
*                                   sqr(r(n)) + 
*                                   sqr(z(n)))
*   + pptermProx * sum(n$(NOT n.first), sqr(f(n) - F_record(n)) + 
*                                   sqr(l(n) - L_record(n)) + 
*                                   sqr(r(n) - R_record(n)) + 
*                                   sqr(z(n) - Z_record(n)))
                                    ;

convexCombEqu(n)$(NOT isLeafNode(n))..
   sum(succ(n,child), riskProb(child)) =e= 1;

objDualEqu(n)$(NOT isLeafNode(n))..
*n1 is all the children of n
   objDual(n) =e= sum(nn1$(nodePath(nn1,n) and not sameas(nn1,n)),
                  prod(nn2$(nodePath(nn1,nn2) and not nodePath(n,nn2)), riskProb(nn2)) * 
                  (floodCost*F(nn1) + lowCost*Z(nn1)
                  + pptermSquare *(sqr(f(nn1)) + 
                                    sqr(l(nn1)) + 
                                    sqr(r(nn1)) + 
                                    sqr(z(nn1)))           
                  
                  ));
* objDual =e= sum(succ(n,child), riskProb(child) * (floodCost*F(child) + lowCost*Z(child))) + 
*             sum(succ(n,child), riskProb(child) * objDual);
riskProb.l(n) = prob(n);
riskProb.up(n) = (1-cvar_wt) * prob(n) + cvar_wt * prob(n)/(1-beta); 
riskProb.lo(n) = (1-cvar_wt) * prob(n);
riskProb.fx('n1') = 1;

model mincostEMPManual 'ReSHOP manual reformulation' /objPrimalEqu, deflvl, objDualEqu, convexCombEqu/;
model mincostEMPManualPrimal 'ReSHOP manual primal' /objPrimalEqu,  deflvl/;
model mincostEMPManualDual 'ReSHOP manual dual' /objDualEqu, convexCombEqu/;


mincostEMPManual.holdfixed=1;
mincostEMPManualPrimal.holdfixed = 1;
mincostEMPManualDual.holdfixed = 1;



* alternative risk problem

set nodePath(n,n)
   backwardControl(n)
   backwardControlChild(n);
   alias(n, nn1, nn2, nn3, nn, nnn, grandchild);
nodePath(nn1,nn2) = no;

loop(n,
   nodePath(n,nn1) = sum(succ(parent,n), nodePath(parent,nn1));
   nodePath(n,n) = yes;
);

display nodePath;

free variable
	objDualComp
;

variable
	mult_of_deflvl(n)
;

equation
	objDualEquComp
   FOONC_F_GEQ(n)
   FOONC_F_LEQ(n)
   FOONC_Z_GEQ(n)
   FOONC_Z_LEQ(n)
   FOONC_L_GEQ(n)
   FOONC_L_LEQ(n)
   FOONC_R_GEQ(n)
   FOONC_R_LEQ(n)
	convexCombEquAlternative(n)
;

Positive variable
   f_geq(n) 
   z_geq(n)
   l_geq(n)
   r_geq(n)
;

Negative variable
   f_leq(n) 
   z_leq(n)
   l_leq(n)
   r_leq(n)
;

objDualEquComp..
   objDualComp =e= sum(backwardControl(n), sum(succ(n,child), riskProb(child) * (ccostl(child) + 
                        sum(nn$(nodePath(nn,child) and not sameas(nn,child)), 
                      prod(nnn$(nodePath(nn,nnn) and not nodePath(child,nnn)), riskProb.l(nnn)) * ccostl(nn)))));

convexCombEquAlternative(n)$(backwardControl(n))..
	sum(child$(succ(n,child)), riskprob(child)) =e= 1;

FOONC_F_GEQ(child)$(backwardControlChild(child) and (abs(F.l(child) - F.lo(child)) < 1e-8 or (F.l(child) - F.lo(child) > 1e-8 and F.up(child) - F.l(child) > 1e-8)))..
   floodCost * riskprob(child) * prod(n$(nodePath(child,n) and not sameas(child,n)), riskprob.l(n)) - mult_of_deflvl(child) + eps * f_geq(child) =g= 0;

FOONC_F_LEQ(child)$(backwardControlChild(child) and (abs(F.l(child) - F.up(child)) < 1e-8 or (F.l(child) - F.lo(child) > 1e-8 and F.up(child) - F.l(child) > 1e-8)))..
   floodCost * riskprob(child) * prod(n$(nodePath(child,n) and not sameas(child,n)), riskprob.l(n)) - mult_of_deflvl(child) + eps * f_leq(child) =l= 0;

FOONC_L_GEQ(child)$(backwardControlChild(child) and (abs(L.l(child) - L.lo(child)) < 1e-8 or (L.l(child) - L.lo(child) > 1e-8 and L.up(child) - L.l(child) > 1e-8)))..
   -mult_of_deflvl(child) + sum(succ(child,grandchild), mult_of_deflvl.l(grandchild)) + eps * l_geq(child) =g= 0;

FOONC_L_LEQ(child)$(backwardControlChild(child) and (abs(L.l(child) - L.up(child)) < 1e-8 or (L.l(child) - L.lo(child) > 1e-8 and L.up(child) - L.l(child) > 1e-8)))..
   -mult_of_deflvl(child) + sum(succ(child,grandchild), mult_of_deflvl.l(grandchild)) + eps * l_leq(child) =l= 0;

FOONC_R_GEQ(child)$(backwardControlChild(child) and (abs(R.l(child) - R.lo(child)) < 1e-8 or (R.l(child) - R.lo(child) > 1e-8 and R.up(child) - R.l(child) > 1e-8)))..
   -mult_of_deflvl(child) + eps * r_geq(child) =g= 0;

FOONC_R_LEQ(child)$(backwardControlChild(child) and (abs(R.l(child) - R.up(child)) < 1e-8 or (R.l(child) - R.lo(child) > 1e-8 and R.up(child) - R.l(child) > 1e-8)))..
   -mult_of_deflvl(child) + eps * r_leq(child) =l= 0;

FOONC_Z_GEQ(child)$(backwardControlChild(child) and (abs(Z.l(child) - Z.lo(child)) < 1e-8 or (Z.l(child) - Z.lo(child) > 1e-8 and Z.up(child) - Z.l(child) > 1e-8)))..
   lowCost * riskprob(child) * prod(n$(nodePath(child,n) and not sameas(child,n)), riskprob.l(n)) + mult_of_deflvl(child) + eps * z_geq(child) =g= 0;

FOONC_Z_LEQ(child)$(backwardControlChild(child) and (abs(Z.l(child) - Z.up(child)) < 1e-8 or (Z.l(child) - Z.lo(child) > 1e-8 and Z.up(child) - Z.l(child) > 1e-8)))..
   lowCost * riskprob(child) * prod(n$(nodePath(child,n) and not sameas(child,n)), riskprob.l(n)) + mult_of_deflvl(child) + eps * z_leq(child) =l= 0;
model alternativeDual / objDualEquComp, FOONC_F_GEQ, FOONC_F_LEQ, FOONC_Z_GEQ, FOONC_Z_LEQ, FOONC_L_GEQ, FOONC_L_LEQ, FOONC_R_GEQ, FOONC_R_LEQ 
                         convexCombEquAlternative/;
model originalDual / objDualEquComp, convexCombEquAlternative/;

* nlp for dual problem

equation
	objDualEquComp_nlp
   FOONC_F_GEQ_nlp(n)
   FOONC_F_LEQ_nlp(n)
   FOONC_Z_GEQ_nlp(n)
   FOONC_Z_LEQ_nlp(n)
   FOONC_L_GEQ_nlp(n)
   FOONC_L_LEQ_nlp(n)
   FOONC_R_GEQ_nlp(n)
   FOONC_R_LEQ_nlp(n)
	convexCombEquAlternative_nlp(n)
;

free variable
	objDualComp_nlp
   f_geq_penalty(n)
   f_leq_penalty(n)
   l_geq_penalty(n)
   l_leq_penalty(n)
   r_geq_penalty(n)
   r_leq_penalty(n)
   z_geq_penalty(n)
   z_leq_penalty(n)
;

SCALAR
   pTerm /%pterm%/
;

objDualEquComp_nlp..
   objDualComp_nlp =e= sum(n$(not n.first), prod(nn$(nodePath(n,nn)), riskProb(nn)) * 
                        (ccostl(n) 
                         + pptermSquare *(sqr(f.l(n)) + 
                                          sqr(l.l(n)) + 
                                          sqr(r.l(n)) + 
                                          sqr(z.l(n)))
                        ))
                        - pTerm * sum(n,
                           f_geq_penalty(n) * f_geq_penalty(n) +
                           f_leq_penalty(n) * f_leq_penalty(n) +
                           l_geq_penalty(n) * l_geq_penalty(n) +
                           l_leq_penalty(n) * l_leq_penalty(n) +
                           r_geq_penalty(n) * r_geq_penalty(n) +
                           r_leq_penalty(n) * r_leq_penalty(n) +
                           z_geq_penalty(n) * z_geq_penalty(n) +
                           z_leq_penalty(n) * z_leq_penalty(n) 
                        )
                        ;
   

convexCombEquAlternative_nlp(n)$(not isLeafNode(n))..
	sum(child$(succ(n,child)), riskprob(child)) =e= 1;

FOONC_F_GEQ_nlp(child)$((not sameas(child,'n1')) and (abs(F.l(child) - F.lo(child)) < 1e-8 or (F.l(child) - F.lo(child) > 1e-8 and F.up(child) - F.l(child) > 1e-8)))..
   floodCost * riskprob(child) * prod(n$(nodePath(child,n) and not sameas(child,n)), riskprob(n)) - mult_of_deflvl(child) + eps * f_geq(child) + f_geq_penalty(child)
* FOONC of square version
   + (2 * pptermSquare * f.l(child)) * riskprob(child) * prod(n$(nodePath(child,n) and not sameas(child,n)), riskprob(n))
*   + 2 * pptermSquare * (f.l(child))
*   + 2 * pptermProx * (f.l(child) - F_record(child))
   =g= 0
   ;

FOONC_F_LEQ_nlp(child)$((not sameas(child,'n1')) and (abs(F.l(child) - F.up(child)) < 1e-8 or (F.l(child) - F.lo(child) > 1e-8 and F.up(child) - F.l(child) > 1e-8)))..
   floodCost * riskprob(child) * prod(n$(nodePath(child,n) and not sameas(child,n)), riskprob(n)) - mult_of_deflvl(child) + eps * f_leq(child) + f_leq_penalty(child)
* FOONC of square version
   + (2 * pptermSquare * f.l(child)) * riskprob(child) * prod(n$(nodePath(child,n) and not sameas(child,n)), riskprob(n))
* + 2 * pptermSquare * (f.l(child))
* + 2 * pptermProx * (f.l(child) - F_record(child))
   =l= 0
   ;

FOONC_L_GEQ_nlp(child)$((not sameas(child,'n1')) and (abs(L.l(child) - L.lo(child)) < 1e-8 or (L.l(child) - L.lo(child) > 1e-8 and L.up(child) - L.l(child) > 1e-8)))..
   -mult_of_deflvl(child) + sum(succ(child,grandchild), mult_of_deflvl(grandchild)) + eps * l_geq(child) + l_geq_penalty(child)
* FOONC of square version
   + (2 * pptermSquare * l.l(child)) * riskprob(child) * prod(n$(nodePath(child,n) and not sameas(child,n)), riskprob(n))
* + 2 * pptermSquare * (l.l(child))
* + 2 * pptermProx * (l.l(child) - L_record(child))
   =g= 0
   ;

FOONC_L_LEQ_nlp(child)$((not sameas(child,'n1')) and (abs(L.l(child) - L.up(child)) < 1e-8 or (L.l(child) - L.lo(child) > 1e-8 and L.up(child) - L.l(child) > 1e-8)))..
   -mult_of_deflvl(child) + sum(succ(child,grandchild), mult_of_deflvl(grandchild)) + eps * l_leq(child) + l_leq_penalty(child)
* FOONC of square version
   + (2 * pptermSquare * l.l(child)) * riskprob(child) * prod(n$(nodePath(child,n) and not sameas(child,n)), riskprob(n))
* + 2 * pptermSquare * (l.l(child))
* + 2 * pptermProx * (l.l(child) - L_record(child))
   =l= 0
   ;

FOONC_R_GEQ_nlp(child)$((not sameas(child,'n1')) and (abs(R.l(child) - R.lo(child)) < 1e-8 or (R.l(child) - R.lo(child) > 1e-8 and R.up(child) - R.l(child) > 1e-8)))..
   -mult_of_deflvl(child) + eps * r_geq(child) + r_geq_penalty(child)
* FOONC of square version
   + (2 * pptermSquare * r.l(child)) * riskprob(child) * prod(n$(nodePath(child,n) and not sameas(child,n)), riskprob(n))
* + 2 * pptermSquare * (r.l(child))
* + 2 * pptermProx * (r.l(child) - R_record(child))
   =g= 0
   ;

FOONC_R_LEQ_nlp(child)$((not sameas(child,'n1')) and (abs(R.l(child) - R.up(child)) < 1e-8 or (R.l(child) - R.lo(child) > 1e-8 and R.up(child) - R.l(child) > 1e-8)))..
   -mult_of_deflvl(child) + eps * r_leq(child) + r_leq_penalty(child)
* FOONC of square version
   + (2 * pptermSquare * r.l(child)) * riskprob(child) * prod(n$(nodePath(child,n) and not sameas(child,n)), riskprob(n))
* + 2 * pptermSquare * (r.l(child))
* + 2 * pptermProx * (r.l(child) - R_record(child))
   =l= 0
   ;

FOONC_Z_GEQ_nlp(child)$((not sameas(child,'n1')) and (abs(Z.l(child) - Z.lo(child)) < 1e-8 or (Z.l(child) - Z.lo(child) > 1e-8 and Z.up(child) - Z.l(child) > 1e-8)))..
   lowCost * riskprob(child) * prod(n$(nodePath(child,n) and not sameas(child,n)), riskprob(n)) + mult_of_deflvl(child) + eps * z_geq(child) + z_geq_penalty(child)
* FOONC of square version
   + (2 * pptermSquare * z.l(child)) * riskprob(child) * prod(n$(nodePath(child,n) and not sameas(child,n)), riskprob(n)) 
* + 2 * pptermSquare * (z.l(child))
* + 2 * pptermProx * (z.l(child) - Z_record(child))
   =g= 0
   ;

FOONC_Z_LEQ_nlp(child)$((not sameas(child,'n1')) and (abs(Z.l(child) - Z.up(child)) < 1e-8 or (Z.l(child) - Z.lo(child) > 1e-8 and Z.up(child) - Z.l(child) > 1e-8)))..
   lowCost * riskprob(child) * prod(n$(nodePath(child,n) and not sameas(child,n)), riskprob(n)) + mult_of_deflvl(child) + eps * z_leq(child) + z_leq_penalty(child) 
* FOONC of square version
   + (2 * pptermSquare * z.l(child)) * riskprob(child) * prod(n$(nodePath(child,n) and not sameas(child,n)), riskprob(n)) 
* + 2 * pptermSquare * (z.l(child))
* + 2 * pptermProx * (z.l(child) - Z_record(child))
   =l= 0
   ;

model dualNLP /
               objDualEquComp_nlp
               FOONC_F_GEQ_nlp
               FOONC_F_LEQ_nlp
               FOONC_Z_GEQ_nlp
               FOONC_Z_LEQ_nlp
               FOONC_L_GEQ_nlp
               FOONC_L_LEQ_nlp
               FOONC_R_GEQ_nlp
               FOONC_R_LEQ_nlp
               convexCombEquAlternative_nlp
               /; 

equation
   objDualEqu_nlp
   convexCombEqu_nlp(n)
;

free variable
   objDual_nlp
;

objDualEqu_nlp..
   objDual_nlp =e= sum(n$(not n.first), prod(nn$(nodePath(n,nn)), riskProb(nn)) * 
                        (ccostl(n)));
convexCombEqu_nlp(n)$(not isLeafNode(n))..
	sum(child$(succ(n,child)), riskprob(child)) =e= 1;

model originalDual_NLP /objDualEqu_nlp
                        convexCombEqu_nlp/;

* fix-up model for rho (the multiplier of convex comb)

Equations
   riskprob_GEQ(n)
   riskprob_LEQ(n)
   dummyObjFunc
;

Variable
   rho(n)    variable for the convex combination constraint multiplier
   dummyObj  dummy variables that has no meaning
;

Positive Variable
   GDummy(n)
   LDummy(n)
   penRhoGEQ(n)
   penRhoLEQ(n)
;

dummyObjFunc..
   dummyObj =e= sum(n, penRhoGEQ(n) + penRhoLEQ(n));

riskprob_GEQ(child)$((not sameas('n1',child)) and (abs(riskProb.l(child) - riskProb.lo(child)) < 1e-8 or (riskProb.l(child) - riskProb.lo(child) > 1e-8 and riskProb.up(child) - riskProb.l(child) > 1e-8)))..
   - (ccostl(child) 
      + pptermSquare *(sqr(f.l(child)) + 
                        sqr(l.l(child)) + 
                        sqr(r.l(child)) + 
                        sqr(z.l(child)))
   )
   + sum(nn$(nodePath(nn,child) and not sameas(nn,child)),
                        - prod(nnn$(nodePath(nn,nnn) and ord(nnn) > ord(child)), riskprob.l(nnn)) * 
                        (ccostl(nn)
                         + pptermSquare *(sqr(f.l(nn)) + 
                                          sqr(l.l(nn)) + 
                                          sqr(r.l(nn)) + 
                                          sqr(z.l(nn)))
                        )
                        ) - sum(n$(succ(n,child)), rho(n)) + penRhoGEQ(child) =g= 0;
               
riskprob_LEQ(child)$((not sameas('n1',child)) and (abs(riskProb.l(child) - riskProb.up(child)) < 1e-8 or (riskProb.l(child) - riskProb.lo(child) > 1e-8 and riskProb.up(child) - riskProb.l(child) > 1e-8)))..
   - (ccostl(child) 
      + pptermSquare *(sqr(f.l(child)) + 
                        sqr(l.l(child)) + 
                        sqr(r.l(child)) + 
                        sqr(z.l(child)))
   ) 
   + sum(nn$(nodePath(nn,child) and not sameas(nn,child)),
                        - prod(nnn$(nodePath(nn,nnn) and ord(nnn) > ord(child)), riskprob.l(nnn)) * 
                        (ccostl(nn)
                         + pptermSquare *(sqr(f.l(nn)) + 
                                          sqr(l.l(nn)) + 
                                          sqr(r.l(nn)) + 
                                          sqr(z.l(nn)))
                        )
                        ) - sum(n$(succ(n,child)), rho(n)) - penRhoLEQ(child) =l= 0;

model findRho /dummyObjFunc, riskprob_GEQ, riskprob_LEQ/;

* dummyObjFunc..
*    dummyObj =e= 0;

* riskprob_GEQ(child)$((not sameas('n1',child)) and (abs(riskProb.l(child) - riskProb.lo(child)) < 1e-8 or (riskProb.l(child) - riskProb.lo(child) > 1e-8 and riskProb.up(child) - riskProb.l(child) > 1e-8)))..
*    - ccostl(child) + sum(nn$(nodePath(nn,child) and not sameas(nn,child)),
*                         - prod(nnn$(nodePath(nn,nnn) and ord(nnn) > ord(child)), riskprob.l(nnn)) * ccostl(nn)) - sum(n$(succ(n,child)), rho(n)) =g= 0;
               
* riskprob_LEQ(child)$((not sameas('n1',child)) and (abs(riskProb.l(child) - riskProb.up(child)) < 1e-8 or (riskProb.l(child) - riskProb.lo(child) > 1e-8 and riskProb.up(child) - riskProb.l(child) > 1e-8)))..
*    - ccostl(child) + sum(nn$(nodePath(nn,child) and not sameas(nn,child)),
*                         - prod(nnn$(nodePath(nn,nnn) and ord(nnn) > ord(child)), riskprob.l(nnn)) * ccostl(nn)) - sum(n$(succ(n,child)), rho(n)) =l= 0;

* model findRho /dummyObjFunc, riskprob_GEQ, riskprob_LEQ/;


* model find the multiplier of primal constraint when the other stuffs are fixed

equation
   FOONC_F_GEQ_fixed(n)
   FOONC_F_LEQ_fixed(n)
   FOONC_Z_GEQ_fixed(n)
   FOONC_Z_LEQ_fixed(n)
   FOONC_L_GEQ_fixed(n)
   FOONC_L_LEQ_fixed(n)
   FOONC_R_GEQ_fixed(n)
   FOONC_R_LEQ_fixed(n)
;

   

FOONC_F_GEQ_fixed(child)$(backwardControlChild(child) and (abs(F.l(child) - F.lo(child)) < 1e-8 or (F.l(child) - F.lo(child) > 1e-8 and F.up(child) - F.l(child) > 1e-8)))..
   floodCost * riskprob.l(child) * prod(n$(nodePath(child,n) and not sameas(child,n)), riskprob.l(n)) - mult_of_deflvl(child) =g= 0;

FOONC_F_LEQ_fixed(child)$(backwardControlChild(child) and (abs(F.l(child) - F.up(child)) < 1e-8 or (F.l(child) - F.lo(child) > 1e-8 and F.up(child) - F.l(child) > 1e-8)))..
   floodCost * riskprob.l(child) * prod(n$(nodePath(child,n) and not sameas(child,n)), riskprob.l(n)) - mult_of_deflvl(child) =l= 0;

FOONC_L_GEQ_fixed(child)$(backwardControlChild(child) and (abs(L.l(child) - L.lo(child)) < 1e-8 or (L.l(child) - L.lo(child) > 1e-8 and L.up(child) - L.l(child) > 1e-8)))..
   -mult_of_deflvl(child) + sum(succ(child,grandchild), mult_of_deflvl(grandchild)) =g= 0;

FOONC_L_LEQ_fixed(child)$(backwardControlChild(child) and (abs(L.l(child) - L.up(child)) < 1e-8 or (L.l(child) - L.lo(child) > 1e-8 and L.up(child) - L.l(child) > 1e-8)))..
   -mult_of_deflvl(child) + sum(succ(child,grandchild), mult_of_deflvl(grandchild)) =l= 0;

FOONC_R_GEQ_fixed(child)$(backwardControlChild(child) and (abs(R.l(child) - R.lo(child)) < 1e-8 or (R.l(child) - R.lo(child) > 1e-8 and R.up(child) - R.l(child) > 1e-8)))..
   -mult_of_deflvl(child) =g= 0;

FOONC_R_LEQ_fixed(child)$(backwardControlChild(child) and (abs(R.l(child) - R.up(child)) < 1e-8 or (R.l(child) - R.lo(child) > 1e-8 and R.up(child) - R.l(child) > 1e-8)))..
   -mult_of_deflvl(child) =l= 0;

FOONC_Z_GEQ_fixed(child)$(backwardControlChild(child) and (abs(Z.l(child) - Z.lo(child)) < 1e-8 or (Z.l(child) - Z.lo(child) > 1e-8 and Z.up(child) - Z.l(child) > 1e-8)))..
   lowCost * riskprob.l(child) * prod(n$(nodePath(child,n) and not sameas(child,n)), riskprob.l(n)) + mult_of_deflvl(child) =g= 0;

FOONC_Z_LEQ_fixed(child)$(backwardControlChild(child) and (abs(Z.l(child) - Z.up(child)) < 1e-8 or (Z.l(child) - Z.lo(child) > 1e-8 and Z.up(child) - Z.l(child) > 1e-8)))..
   lowCost * riskprob.l(child) * prod(n$(nodePath(child,n) and not sameas(child,n)), riskprob.l(n)) + mult_of_deflvl(child) =l= 0;

model findPrimalMultipliers /dummyObjFunc, 
                              FOONC_F_GEQ_fixed
                              FOONC_F_LEQ_fixed
                              FOONC_Z_GEQ_fixed
                              FOONC_Z_LEQ_fixed
                              FOONC_L_GEQ_fixed
                              FOONC_L_LEQ_fixed
                              FOONC_R_GEQ_fixed
                              FOONC_R_LEQ_fixed/;


* define VIs for extra linear constraints

equation
   FOONC_F_VI(n)
   FOONC_L_VI(n)
   FOONC_R_VI(n)
   FOONC_Z_VI(n)
;

free variable
   f_vi(n)
   l_vi(n)
   r_vi(n)
   z_vi(n)
;

FOONC_F_VI(child)$(not sameas(child,'n1'))..
   floodCost * riskprob(child) * prod(n$(nodePath(child,n) and not sameas(child,n)), riskprob(n)) - mult_of_deflvl(child) + eps * f_vi(child) =n= 0;

FOONC_L_VI(child)$(not sameas(child,'n1'))..
   -mult_of_deflvl(child) + sum(succ(child,grandchild), mult_of_deflvl(grandchild)) + eps * l_vi(child) =n= 0;

FOONC_R_VI(child)$(not sameas(child,'n1'))..
   -mult_of_deflvl(child) + eps * r_vi(child) =n= 0;

FOONC_Z_VI(child)$(not sameas(child,'n1'))..
   lowCost * riskprob(child) * prod(n$(nodePath(child,n) and not sameas(child,n)), riskprob(n)) + mult_of_deflvl(child) + eps * z_vi(child) =n= 0;

model exactDModel_alternative /objDualEquComp_nlp
                               convexCombEquAlternative_nlp
                               FOONC_F_VI
                               FOONC_L_VI
                               FOONC_R_VI
                               FOONC_Z_VI/;

*********************************************************
* MPEC variation

equation
   FOONC_F_VI_MPEC(n)
   FOONC_L_VI_MPEC(n)
   FOONC_R_VI_MPEC(n)
   FOONC_Z_VI_MPEC(n)
;

free variable
   err_f(n)
   err_l(n)
   err_r(n)
   err_z(n)
;


FOONC_F_VI_MPEC(child)$(not sameas(child,'n1'))..
   floodCost * riskprob(child) * prod(n$(nodePath(child,n) and not sameas(child,n)), riskprob(n)) - mult_of_deflvl(child) + eps * f_vi(child) + err_f(child)$%penalizePrimalKKT% =n= 0;

FOONC_L_VI_MPEC(child)$(not sameas(child,'n1'))..
   -mult_of_deflvl(child) + sum(succ(child,grandchild), mult_of_deflvl(grandchild)) + eps * l_vi(child) + err_l(child)$%penalizePrimalKKT% =n= 0;

FOONC_R_VI_MPEC(child)$(not sameas(child,'n1'))..
   -mult_of_deflvl(child) + eps * r_vi(child) + err_r(child)$%penalizePrimalKKT% =n= 0;

FOONC_Z_VI_MPEC(child)$(not sameas(child,'n1'))..
   lowCost * riskprob(child) * prod(n$(nodePath(child,n) and not sameas(child,n)), riskprob(n)) + mult_of_deflvl(child) + eps * z_vi(child) + err_z(child)$%penalizePrimalKKT% =n= 0;


equation
   RiskVI(n)
   ConvexCombVI(n)
   MPECObjective
;

free variable
   err(n)  error allowd in the risk vi
   errConvex(n)
   mpecObjVal
;

RiskVI(child)$((not sameas('n1',child)))..
   - ccostl(child) + sum(nn$(nodePath(nn,child) and not sameas(nn,child)),
                        - prod(nnn$(nodePath(nn,nnn) and ord(nnn) > ord(child)), riskprob(nnn)) * ccostl(nn)) - sum(n$(succ(n,child)), rho(n)) + err(child)$%penalizeRisk% =n= 0;

ConvexCombVI(n)$(not isLeafNode(n))..
	sum(child$(succ(n,child)), riskprob(child)) - 1 + errConvex(n)$%penalizeConvex% =n= 0;

MPECObjective..
   mpecObjVal =e= sum(n$(not n.first), (riskWeightError * err(n) * err(n))$%penalizeRisk%
                                       + (err_f(n) * err_f(n) +
                                       err_l(n) * err_l(n) +
                                       err_r(n) * err_r(n) +
                                       err_z(n) * err_z(n))$%penalizePrimalKKT%
                                       +  errConvex(n)$%penalizeConvex%
                                       );


model D_Step_MPEC /MPECObjective
                   RiskVI.riskProb
                   ConvexCombVI.rho
                   FOONC_F_VI_MPEC.f_vi
                   FOONC_L_VI_MPEC.l_vi
                   FOONC_R_VI_MPEC.r_vi
                   FOONC_Z_VI_MPEC.z_vi/;


model D_Step_MCP /
                   RiskVI.riskProb
                   ConvexCombVI.rho
                   FOONC_F_VI_MPEC.f_vi
                   FOONC_L_VI_MPEC.l_vi
                   FOONC_R_VI_MPEC.r_vi
                   FOONC_Z_VI_MPEC.z_vi/;


model D_Step_MPEC_Constraint /MPECObjective
                   RiskVI.riskProb
                   ConvexCombVI.rho
                   FOONC_F_VI_MPEC
                   FOONC_L_VI_MPEC
                   FOONC_R_VI_MPEC
                   FOONC_Z_VI_MPEC/;        


model directNLP /objDualEquComp_nlp,convexCombEquAlternative_nlp/;


equation
   objPrimalEqu_penalized
   riskprob_GEQ_nlp
   riskprob_LEQ_nlp
;

variable
   risk_geq_penalty(n)
   risk_leq_penalty(n)
;

objPrimalEqu_penalized..
   objPrimal =e= sum(n$(NOT n.first), prod(nodePath(n,nn1), riskProb.l(nn1)) * (floodCost*F(n) + lowCost*Z(n)))
            + 0.001 * sum(n, risk_geq_penalty(n) * risk_geq_penalty(n) +
                     risk_leq_penalty(n) * risk_leq_penalty(n))
               ;



* dual KKT in primal problem (sign of rho?)
riskprob_GEQ_nlp(child)$((not sameas('n1',child)) and (abs(riskProb.l(child) - riskProb.lo(child)) < 1e-8 or (riskProb.l(child) - riskProb.lo(child) > 1e-8 and riskProb.up(child) - riskProb.l(child) > 1e-8)))..
   - ccost(child) + sum(nn$(nodePath(nn,child) and not sameas(nn,child)),
                        - prod(nnn$(nodePath(nn,nnn) and ord(nnn) > ord(child)), riskprob.l(nnn)) * ccost(nn)) - sum(n$(succ(n,child)), convexCombEquAlternative_nlp.m(n)) + risk_geq_penalty(child) =g= 0;
               
riskprob_LEQ_nlp(child)$((not sameas('n1',child)) and (abs(riskProb.l(child) - riskProb.up(child)) < 1e-8 or (riskProb.l(child) - riskProb.lo(child) > 1e-8 and riskProb.up(child) - riskProb.l(child) > 1e-8)))..
   - ccost(child) + sum(nn$(nodePath(nn,child) and not sameas(nn,child)),
                        - prod(nnn$(nodePath(nn,nnn) and ord(nnn) > ord(child)), riskprob.l(nnn)) * ccost(nn)) - sum(n$(succ(n,child)), convexCombEquAlternative_nlp.m(n)) + risk_leq_penalty(child) =l= 0;



model primalNLP /objPrimalEqu_penalized
                 deflvl
   riskprob_GEQ_nlp
   riskprob_LEQ_nlp
                /;

