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

gasEnEqulibrium_social.optfile = 1;
gasEnEqulibrium_RN_social.optfile = 1;

* let risk neutral model to ignore fixed variable
gasEnEqulibrium_RN_social.holdFixed = 1;

* set reshop as emp solver
option emp=reshop;

* fix probability for each non-root node
loop(n$sn(n),
	y_social.fx(n) = prob(n);
);

* Primal PATH problem
embeddedcode reshop:
realAgent(a): min obj(a) x(a,i,n) q(a,i,n) s(a,i,n) defobj_social(a) defFlow(a,i,n)
priceAgent(i,n)$(sn(n)): vi defSupplydemand(i,n) p(i,n)
equ: Nash(realAgent(a),priceAgent(i,n)$(sn(n)))
endembeddedcode

solve gasEnEqulibrium_RN_social using emp;

abort$(gasEnEqulibrium_RN_social.modelstat > 2 or gasEnEqulibrium_RN_social.solveStat > 1 ) '##################### gasEnEqulibrium_RN_social fails to solve the model to optimality';

* release y variables (unfix them)
y_social.lo(n)$(not nt(n,'t0')) = (1 - lambda)*prob(n);
y_social.up(n)$(not nt(n,'t0')) = (1 - lambda)*prob(n) + lambda*prob(n)/(1-alpha);

* Make sure the level value is correctly set
loop(n$sn(n),
	y_social.l(n) = prob(n);
);

* solve the full model
embeddedcode reshop:
realAgent(a): min obj(a) x(a,i,n) q(a,i,n) s(a,i,n) defobj_social(a) defFlow(a,i,n)
riskAgent(n)$(not leafn(n)): max yobj_social(n) y_social(child)$(succ(n,child)) defsupp_social(n) defriskSet_social(n)
priceAgent(i,n)$(sn(n)): vi defSupplydemand(i,n) p(i,n)
equ: Nash(realAgent(a),riskAgent(n)$(not leafn(n)),priceAgent(i,n)$(sn(n)))
endembeddedcode

option emp=reshop;
solve gasEnEqulibrium_social using emp;

abort$(gasEnEqulibrium_social.modelstat > 2 or gasEnEqulibrium_social.solveStat > 1 ) '##################### gasEnEqulibrium_social fails to solve the model to optimality';
* scalar merit;
* merit = meritTM;
* display merit;