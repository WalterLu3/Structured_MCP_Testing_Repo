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

y_social.l(n)$sn(n) = prob(n);
defriskSet_social.m(n)$[not leafn(n)] = 1;

* solve the original model
embeddedcode reshop:
realAgent(a): min obj(a) x(a,i,n) q(a,i,n) s(a,i,n) defobj_social(a) defFlow(a,i,n)
riskAgent(n)$(not leafn(n)): max yobj_social(n) y_social(child)$(succ(n,child)) defsupp_social(n) defriskSet_social(n)
priceAgent(i,n)$(sn(n)): vi defSupplydemand(i,n) p(i,n)
equ: Nash(realAgent(a),riskAgent(n)$(not leafn(n)),priceAgent(i,n)$(sn(n)))
endembeddedcode

gasEnEqulibrium_social.optfile = 1;

solve gasEnEqulibrium_social using emp;

abort$(gasEnEqulibrium_social.modelstat > 2 or gasEnEqulibrium_social.solveStat > 1 ) '##################### gasEnEqulibrium_social fails to solve the model to optimality';

scalar merit;
merit = meritTM;
display merit;