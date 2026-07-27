* file: algorithm_PATH-RN.gms

* purpose: algorithm declaration

***** Algorithm : PATH-RN *****
** Details: solve a risk neutral model followed by PATH algorithm



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
gasEnEqulibrium_RN.optfile = 1;

* let risk neutral model to ignore fixed variable
gasEnEqulibrium_RN.holdFixed = 1;

* set reshop as emp solver
option emp=reshop;

* fix probability for each non-root node
loop(n$sn(n),
	y.fx(a,n) = prob(n);
);

* Primal PATH problem
embeddedcode reshop:
realAgent(a): min obj(a) x(a,i,n) q(a,i,n) s(a,i,n) defobj(a) defFlow(a,i,n)
priceAgent(i,n)$(sn(n)): vi defSupplydemand(i,n) p(i,n)
equ: Nash(realAgent(a),priceAgent(i,n)$(sn(n)))
endembeddedcode

solve gasEnEqulibrium_RN using emp;

abort$(gasEnEqulibrium_RN.modelstat > 2 or gasEnEqulibrium_RN.solveStat > 1 ) '##################### gasEnEqulibrium_RN fails to solve the model to optimality';

* release y variables (unfix them)
y.lo(a,n)$(not nt(n,'t0')) = (1 - lambda)*prob(n);
y.up(a,n)$(not nt(n,'t0')) = (1 - lambda)*prob(n) + lambda*prob(n)/(1-alpha);

* Make sure the level value is correctly set
loop(n$sn(n),
	y.l(a,n) = prob(n);
);

* solve the full model
embeddedcode reshop:
realAgent(a): min obj(a) x(a,i,n) q(a,i,n) s(a,i,n) defobj(a) defFlow(a,i,n)
riskAgent(a,n)$(not leafn(n)): max yobj(a,n) y(a,child)$(succ(n,child)) defsupp(a,n) defriskSet(a,n)
priceAgent(i,n)$(sn(n)): vi defSupplydemand(i,n) p(i,n)
equ: Nash(realAgent(a),riskAgent(a,n)$(not leafn(n)),priceAgent(i,n)$(sn(n)))
endembeddedcode

option emp=reshop;
solve gasEnEqulibrium using emp;

abort$(gasEnEqulibrium.modelstat > 2 or gasEnEqulibrium.solveStat > 1 ) '##################### gasEnEqulibrium fails to solve the model to optimality';
