* file: algorithm_PATH.gms

* purpose: algorithm declaration


***** Algorithm : PATH *****
** Details: formulate stochastic risk equilibrium with risk averse players as a single MCP

* option file reshop.opt and path.opt to disable crash method.
* We do this because we want to use the accurate starting info.
file reshopOptFile /reshop.opt/;
put reshopOptFile;
put 'subsolveropt 1'/;
putclose reshopOptFile;


file pathOptFile /path.opt/;
put pathOptFile;
put 'crash_method none'/;
put 'crash_perturb 0'/;
put 'factorization_method lusol'/;
putclose pathOptFile;

gasEnEqulibrium.optfile = 1;

* set reshop as emp solver
option emp=reshop;

* starting point
x.l(a,i,n)$[ia(i,a) and sn(n)] = 0.5*(x.lo(a,i,n) + x.up(a,i,n));
q.l(a,i,n)$[ia(i,a) and sn(n)] = 0.5*(q.lo(a,i,n) + q.up(a,i,n));
s.l(a,i,n)$[ia(i,a) and sn(n)] = 1;

defFlow.m(a,i,n)$[ia(i,a) and sn(n)] = 1;
p.l(i,n)$sn(n) = 1;

y.l(a,n)$sn(n) = prob(n);
defriskSet.m(a,n)$[not leafn(n)] = 1;



* solve the original model
embeddedcode reshop:
realAgent(a): min obj(a) x(a,i,n) q(a,i,n) s(a,i,n) defobj(a) defFlow(a,i,n)
riskAgent(a,n)$(not leafn(n)): max yobj(a,n) y(a,child)$(succ(n,child)) defsupp(a,n) defriskSet(a,n)
priceAgent(i,n)$(sn(n)): vi defSupplydemand(i,n) p(i,n)
equ: Nash(realAgent(a),riskAgent(a,n)$(not leafn(n)),priceAgent(i,n)$(sn(n)))
endembeddedcode

gasEnEqulibrium.optfile = 1;

solve gasEnEqulibrium using emp;

abort$(gasEnEqulibrium.modelstat > 2 or gasEnEqulibrium.solveStat > 1 ) '##################### gasEnEqulibrium fails to solve the model to optimality';


* parameter
*     solutionX(a,i,n),
*     solutionQ(a,i,n),
*     solutionS(a,i,n),
*     solutionP(i,n);

* solutionX(a,i,n) = x.l(a,i,n);
* solutionQ(a,i,n) = q.l(a,i,n);
* solutionS(a,i,n) = s.l(a,i,n);
* solutionP(i,n) = p.l(i,n);


* execute_unload "test_answer_1.gdx", a=a, n=n, i=i, solutionX=solutionX, solutionQ=solutionQ, solutionS=solutionS, solutionP=solutionP;