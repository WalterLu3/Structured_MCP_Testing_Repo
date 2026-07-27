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

gasEnEqulibrium_dynamic.optfile = 1;

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

* * main model
* controlN(a,n) = yes;
* controlN(a,n)$(leafn(n)) = no;

* solve the original model

set notLeafNotRoot(n);
notLeafNotRoot(n) = no;
notLeafNotRoot(n)$(not leafn(n) and sn(n)) = yes;

embeddedcode reshop:
realAgent(a,'n0'): min obj_dynamic(a,'n0') + riskAgent(a,'n0').valfn
                    x(a,i,'n0') 
                    defobj_dynamic(a,'n0') 
realAgent(a,n)$(notLeafNotRoot(n)): min obj_dynamic(a,n) + riskAgent(a,n).valfn
                    x(a,i,n) 
                    q(a,i,n) 
                    s(a,i,n)
                    defobj_dynamic(a,n) 
                    defFlow(a,i,n)
realAgent(a,n)$(leafn(n)): min obj_dynamic(a,n)
                    x(a,i,n)
                    q(a,i,n) 
                    s(a,i,n)
                    defobj_dynamic(a,n) 
                    defFlow(a,i,n)
riskAgent(a,n)$(not leafn(n)): MP('ecvarup', realAgent(a,child).valfn$succ(n,child),tail=tail, risk_wt=%lambda%, prob=prob(child)$succ(n,child))
priceAgent(i,n)$(sn(n)): vi defSupplydemand(i,n) p(i,n)
equ: Nash(realAgent(a,'n0'),priceAgent(i,n)$(sn(n)))
endembeddedcode

gasEnEqulibrium_dynamic.optfile = 1;

solve gasEnEqulibrium_dynamic using emp;

abort$(gasEnEqulibrium_dynamic.modelstat > 2 or gasEnEqulibrium_dynamic.solvestat > 1) '##################### Dynamic Formulation did not solve the model to optimality';