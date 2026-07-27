***********************************************
* check solution against the original model
***********************************************

* We fix the primal solution of price and producer variagbles
* and solve the original model to get the corresponding.
* risk probability. Then we solve the full model again.

gasEnEqulibrium_Dual.holdFixed = 1;

parameter solutionRecord_x(a,i,n)
          solutionRecord_q(a,i,n)
          solutionRecord_s(a,i,n)
          solutionRecord_p(i,n);

solutionRecord_x(a,i,n)$(sn(n)) = x.l(a,i,n);
solutionRecord_q(a,i,n)$(sn(n)) = q.l(a,i,n);
solutionRecord_s(a,i,n)$(sn(n)) = s.l(a,i,n);
solutionRecord_p(i,n)$(sn(n)) = p.l(i,n);

x.fx(a,i,n)$(sn(n)) = x.l(a,i,n);
q.fx(a,i,n)$(sn(n)) = q.l(a,i,n);
s.fx(a,i,n)$(sn(n)) = s.l(a,i,n);
p.fx(i,n)$(sn(n)) = p.l(i,n);

*solve the original model with primal variables fixed
embeddedcode reshop:
riskAgent(a,n)$(not leafn(n)): max yobj(a,n) y(a,child)$(succ(n,child)) 
                defsupp(a,n) defriskSet(a,n)
equ: Nash(riskAgent(a,n)$(not leafn(n)))
endembeddedcode

gasEnEqulibrium_Dual.optfile = 1;

solve gasEnEqulibrium_Dual using emp;

abort$(gasEnEqulibrium_Dual.modelstat > 2 or gasEnEqulibrium_Dual.solveStat > 1 ) '##################### gasEnEqulibrium_Dual fails to solve the model to optimality';


x.up(a,i,n)$(sn(n)) = xup;
x.lo(a,i,n)$(sn(n)) = xlo;
q.up(a,i,n)$(sn(n)) = Cap(a,i,n);
q.lo(a,i,n)$(sn(n)) = 0;
s.up(a,i,n)$(sn(n)) = +inf;
s.lo(a,i,n)$(sn(n)) = 0;
p.up(i,n)$(sn(n)) = +inf;
p.lo(i,n)$(sn(n)) = 0;


*solve the original model again by unfixing all variables
embeddedcode reshop:
realAgent(a): min obj(a) x(a,i,n) q(a,i,n) s(a,i,n) defobj(a) defFlow(a,i,n)
riskAgent(a,n)$(not leafn(n)): max yobj(a,n) y(a,child)$(succ(n,child)) defsupp(a,n) defriskSet(a,n)
priceAgent(i,n)$(sn(n)): vi defSupplydemand(i,n) p(i,n)
equ: Nash(realAgent(a),riskAgent(a,n)$(not leafn(n)),priceAgent(i,n)$(sn(n)))
endembeddedcode

gasEnEqulibrium.optfile = 1;

solve gasEnEqulibrium using emp;

abort$(gasEnEqulibrium.modelstat > 2 or gasEnEqulibrium.solveStat > 1 ) '##################### gasEnEqulibrium fails to solve the model to optimality';

* compute the solution difference
scalar solutionResidual /0/;

loop((a,i,n)$(sn(n)),
    solutionResidual = solutionResidual + abs(x.l(a,i,n) - solutionRecord_x(a,i,n))
        + abs(q.l(a,i,n) - solutionRecord_q(a,i,n))
        + abs(s.l(a,i,n) - solutionRecord_s(a,i,n));
);

loop((i,n)$(sn(n)),
    solutionResidual = solutionResidual + abs(p.l(i,n) - solutionRecord_p(i,n));
);

display solutionResidual;

put_utility 'log' / '################ Primal Solution Difference from the Original Formulation =' solutionResidual;