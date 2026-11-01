option emp=reshop;

$if not set nstage    $eval nstage 3
$if not set nchildren $eval nchildren 3

$macro ccostl(n_temp) \
   (floodCost * F.l(n_temp) + lowCost * Z.l(n_temp) + holdCost * L.l(n_temp))

$eval x '0' $eval i '0' $eval num_nodes '0'

$label rep $eval num_nodes '%num_nodes% + power(%nchildren%,%i%)' $eval i '%i%+1'

$ifE %i%<%nstage% $goto rep
* TODO why does the following not work:
* $ifE %i% < %nstage% $goto rep
set 
     t Time periods                            /t1*t%nstage%/
     n set of nodes                       /n1*n%num_nodes%/
     succ(n,n)  Successor relationship
     nt(n,t) n belongs to time stage t;

parameters
           ndelta(n)  'Water inflow at each node'
           prob(n)    'Conditional probability';

set pp /low, normal, high/;

table rain_vals(*,pp)
             low    normal    high
   dry       -50      100     250
   wet        50      150     350;

ALIAS (n,child,parent);

succ(n,child)$(ord(child) >= %nchildren%*ord(n)-(%nchildren%-2) AND
               ord(child) <= %nchildren%*ord(n)+1) = yes;

nt(n,t)$(ord(t)=(floor(log((%nchildren% - 1)*(ord(n) - 1) + 1) / log(%nchildren%) + 1e-9) + 1)) = yes;


parameter
    prob_vals(pp) /
        low     0.25
        normal  0.50
        high    0.25
    /;

prob(n)$(not n.first) =
    sum(pp$(pp.pos = 1 + mod(ord(n)+1,%nchildren%)),
        prob_vals(pp));

ndelta(n)$nt(n,'t2') =
    sum(pp$(pp.pos = 1 + mod(ord(n)+1, %nchildren%)),
        rain_vals('dry',pp));

ndelta(n)$nt(n,'t3') =
    sum(pp$(pp.pos = 1 + mod(ord(n)+1, %nchildren%)),
        rain_vals('wet',pp));



VARIABLE EC               'Total Cost';

POSITIVE VARIABLES
		   F(n)             'Floodwater released (mm)',
           L(n)             'Reservoir water level -- EOP',
		   R(n)             'Normal release of water (mm)',
		   Z(n)             'Water imports (mm)';

scalar r_max /200/
       l_max /250/
       l_start /100/;

R.up(n) = r_max;
L.up(n) = l_max;
L.fx(n)$(n.first) = l_start;


scalar    tail 'tail of the CVaR' /0.73/
          cvar_wt 'weight of the CVaR' /0.3/
          floodCost  'Flooding penalty cost thousand CHF per mm'   /10/
          lowCost    'Water importation cost thousand CHF per mm'  /5/
          holdCost   'level inventory cost'                        /1/
          beta
          ;

beta = 1-tail;

VARIABLE EC               'Total Cost';

VARIABLES          v(n)    'Var value at each non-leaf node',
                   cost(n) 'total cost at each node';

POSITIVE VARIABLES y(n)    'Contribution of the cost for each node';

EQUATIONS ecdef, ldef; 

EQUATIONS cvar_ineq(n,n), defcost(n), totalCost;

cvar_ineq(n,child)$(succ(n,child))..
   y(child) =G= cost(child) - v(n);

defcost(n)..
   cost(n) =G= (floodcost*F(n)+lowCost*Z(n)+holdCost*L(n))$(NOT n.first) + 
   (
          cvar_wt * [ v(n) + [1/(1-beta)] * sum(succ(n,child), prob(child)*y(child)) ] +
      (1-cvar_wt) * [ sum(succ(n,child), prob(child)*cost(child)) ]
   )$(sum(succ(n,child), yes));

totalCost..
   EC =E= sum(n$n.first, cost(n));


ldef(n)$[NOT n.first].. L(n) =e= sum{ succ(parent,n), L(parent)} + ndelta(n)+Z(n)-R(n)-F(n);

MODEL mincost / totalCost, defcost, cvar_ineq, ldef /;

solve mincost using lp minimizing EC;


***************************
* equilibrium formulation *
***************************

alias(n, nn, nnn, nn1, nn2);

set
   nodePath(n,nn) 'nn is in path from root to node n'
   isLeafNode(n) 'indicator for leaf nodes';


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
   deflvl(n)
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
   objPrimal =e= sum(n$(NOT n.first), prod(nodePath(n,nn1), riskProb(nn1)) * (floodCost*F(n) + lowCost*Z(n) + holdCost*L(n)
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
deflvl(n)$(NOT n.first)..
    L(n) =E= sum(succ(parent,n), L(parent))
           + ndelta(n) + Z(n) - R(n) - F(n);
convexCombEqu(n)$(NOT isLeafNode(n))..
   sum(succ(n,child), riskProb(child)) =e= 1;

objDualEqu(n)$(NOT isLeafNode(n))..
*n1 is all the children of n
   objDual(n) =e= sum(nn1$(nodePath(nn1,n) and not sameas(nn1,n)),
                  prod(nn2$(nodePath(nn1,nn2) and not nodePath(n,nn2)), riskProb(nn2)) * 
                  (floodCost*F(nn1) + lowCost*Z(nn1) + holdCost*L(nn1)
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

set
   backwardControl(n)
   backwardControlChild(n);

free variable
	objDualComp
;

equation
	objDualEquComp
	convexCombEquAlternative(n)
;

objDualEquComp..
   objDualComp =e= sum(backwardControl(n), sum(succ(n,child), riskProb(child) * (ccostl(child) + 
                        sum(nn$(nodePath(nn,child) and not sameas(nn,child)), 
                      prod(nnn$(nodePath(nn,nnn) and not nodePath(child,nnn)), riskProb.l(nnn)) * ccostl(nn)))));

convexCombEquAlternative(n)$(backwardControl(n))..
	sum(child$(succ(n,child)), riskprob(child)) =e= 1;

model originalDual / objDualEquComp, convexCombEquAlternative/;

********** main algo start ******

set loopN /l1*l1/;

* step 1 run PD with multiple loops:
riskProb.l(n) = prob(n);

loop(loopN,

riskProb.fx(n) = riskProb.l(n);


embeddedCode reshop:
primalNode: min objPrimal L(n) F(n) R(n) Z(n) objPrimalEqu deflvl(n)
endEmbeddedCode

solve mincostEMPManualPrimal using EMP;
abort$(mincostEMPManualPrimal.modelstat > 2) "Error: mincostEMPManualPrimal model did not solve";

riskProb.up(n) = (1-cvar_wt) * prob(n) + cvar_wt * prob(n)/(1-beta); 
riskProb.lo(n) = (1-cvar_wt) * prob(n);
riskProb.fx('n1') = 1;

L.fx(n) = L.l(n);
F.fx(n) = F.l(n);
R.fx(n) = R.l(n);
Z.fx(n) = Z.l(n);


* embeddedCode reshop:
* dualNode(n)$(not isLeafNode(n)): max objDual(n) riskProb(child)$(succ(n,child)) objDualEqu(n) convexCombEqu(n)
* equ: Nash(dualNode(n)$(not isLeafNode(n)))
* endEmbeddedCode

* solve mincostEMPManualDual using EMP;
* abort$(mincostEMPManualDual.modelstat > 2) "Error: mincostEMPManualDual model did not solve";

*display 'Print P step';
*display f.l, z.l, l.l, r.l;
*display riskprob.l;

* dual step
loop(nn1,
   loop(nn2$((ord(nn2) = card(n) - ord(nn1) + 1) and not isLeafNode(nn2)),
* activate correct lp
      backwardControl(n) = no;
      backwardControlChild(n) = no;
      backwardControl(nn2) = yes;
      backwardControlChild(n)$(succ(nn2,n)) = yes;

      solve originalDual using LP maximizing objDualComp;

        display 'Print small D step';
        display f.l, z.l, l.l, r.l;
        display riskprob.l;
*      solve alternativeDual using LP maximizing objDualComp;
   );
);

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
* convexCombEqu.m(n) = -convexCombEqu.m(n);
convexCombEqu.m(n) = -convexCombEquAlternative.m(n);


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


