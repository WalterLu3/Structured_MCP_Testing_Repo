* file: algorithm_PD_PATH.gms

* purpose: algorithm declaration


***** Algorithm : PD followed by PATH solve *****

* option file reshop.opt and path.opt to disable crash method.
* We do this because we want to use the accurate starting info.
* Other options are set based on Jiajie's file

* reshop option file
file reshopOptFile /reshop.opt/;
put reshopOptFile;
put 'subsolveropt 1'/;
putclose reshopOptFile;

file reshopOptFile2 /reshop.op2/;
put reshopOptFile2;
put 'subsolveropt 2'/;
putclose reshopOptFile2;

* path option file

* path.opt : disable crash method (used in primal)
file pathOptFile /path.opt/; 
put pathOptFile;
put 'crash_method none'/;
put 'crash_perturb 0'/;
put 'restart_limit 0'/;
put 'lemke_cycle_limit 30'/;
putclose pathOptFile;

* path.op2 : limit start limit to 0 to allow
*            residual evaluation
file pathOptFile2 /path.op2/;
put pathOptFile2; 
put 'crash_perturb 0'/;
put 'crash_method none'/;
put 'major_iteration_limit 0'/;
putclose pathOptFile2;

gasEnEqulibrium_RN.optfile = 1;

scalar 
	iterationCount     count the number of iterations
	currentResidual    record current residual
	lastResidual       record last residual
;

iterationCount = 0;
currentResidual = 0;
lastResidual = +inf;

set
	mem /m1*m3/
;
parameter
	convexCombMem(a,n,mem)
	memWeight(mem)
*   take record of the last solution
	x_prev(a,i,n)
	q_prev(a,i,n)
	s_prev(a,i,n)
	p_prev(i,n)
	y_prev(a,n)
	defFlow_m(a,i,n)
	defriskSet_m(a,n)
	defSupplydemand_m(i,n)
;
convexCombMem(a,n,mem)$(sn(n)) = prob(n);

memWeight('m1') = 0.5;
memWeight('m2') = 0.25;
memWeight('m3') = 0.25;

x_prev(a,i,n) = 0;
q_prev(a,i,n) = 0;
s_prev(a,i,n) = 0;
p_prev(i,n) = 0;
y_prev(a,n) = 0;
defFlow_m(a,i,n) = 0;
defriskSet_m(a,n) = 0;
defSupplydemand_m(i,n) = 0;

* set reshop as emp solver
option emp = reshop;

* hold fix to treate fixed variable
gasEnEqulibrium_RN.holdFixed = 1;
gasEnEqulibrium_Dual.holdFixed = 1;

while(iterationCount < iterationLimit,
* 	fix y and solve primal agent problem

	if(iterationCount eq 0,
		y.fx(a,n)$sn(n) = prob(n);
	else
		y.fx(a,n)$sn(n) = y.l(a,n);
	)

* solve primal problem
embeddedcode reshop:
realAgent(a): min obj(a) x(a,i,n) q(a,i,n) s(a,i,n) defobj(a) defFlow(a,i,n)
priceAgent(i,n)$(sn(n)): vi defSupplydemand(i,n) p(i,n)
equ: Nash(realAgent(a),priceAgent(i,n)$(sn(n)))
endembeddedcode


	solve gasEnEqulibrium_RN using emp;

*   if bad things happen, exit the loop
	if(gasEnEqulibrium_RN.solvestat > 1 or gasEnEqulibrium_RN.modelstat > 2,
		break;
	);

* 	unfix y
	y.lo(a,n)$(not nt(n,'t0')) = (1 - lambda)*prob(n);
	y.up(a,n)$(not nt(n,'t0')) = (1 - lambda)*prob(n) + lambda*prob(n)/(1-alpha);

*   fix x q s
	x.fx(a,i,n) = x.l(a,i,n);
	q.fx(a,i,n) = q.l(a,i,n);
	s.fx(a,i,n) = s.l(a,i,n);
	p.fx(i,n) = p.l(i,n);

*   solve dual problem
embeddedcode reshop:
riskAgent(a,n)$(not leafn(n)): max yobj(a,n) y(a,child)$(succ(n,child)) 
				defsupp(a,n) defriskSet(a,n)
equ: Nash(riskAgent(a,n)$(not leafn(n)))
endembeddedcode

	solve gasEnEqulibrium_Dual using emp;

	x.up(a,i,n) = xup;
	x.lo(a,i,n) = xlo;
	q.up(a,i,n) = Cap(a,i,n);
	q.lo(a,i,n) = 0;
	s.up(a,i,n) = +inf;
	s.lo(a,i,n) = 0;
	p.up(i,n) = +inf;
	p.lo(i,n) = 0;

* *   check the residual 

embeddedcode reshop:
realAgent(a): min obj(a) x(a,i,n) q(a,i,n) s(a,i,n) defobj(a) defFlow(a,i,n)
riskAgent(a,n)$(not leafn(n)): max yobj(a,n) y(a,child)$(succ(n,child)) defsupp(a,n) defriskSet(a,n)
priceAgent(i,n)$(sn(n)): vi defSupplydemand(i,n) p(i,n)
equ: Nash(realAgent(a),riskAgent(a,n)$(not leafn(n)),priceAgent(i,n)$(sn(n)))
endembeddedcode

	gasEnEqulibrium.optfile = 2;
	solve gasEnEqulibrium using emp;

	currentResidual = meritTM;

*   if the residual is small enough, we break.
	if(gasEnEqulibrium.modelstat le 2,
*       use macro 
        x_prev(a,i,n)$[ia(i,a) and sn(n)] = x.l(a,i,n);
        q_prev(a,i,n)$[ia(i,a) and sn(n)] = q.l(a,i,n);
        s_prev(a,i,n)$[ia(i,a) and sn(n)] = s.l(a,i,n);
        p_prev(i,n)$sn(n) = p.l(i,n);
        y_prev(a,n)$sn(n) = y.l(a,n);
        defFlow_m(a,i,n)$[ia(i,a) and sn(n)] = defFlow.m(a,i,n);
        defriskSet_m(a,n)$[not leafn(n)] = defriskSet.m(a,n);
        defSupplydemand_m(i,n)$sn(n) = defSupplydemand.m(i,n);
		break;
	);

	if(iterationCount > %testNumber% and currentResidual >= lastResidual,
*       use macro 
        q.l(a,i,n)$[ia(i,a) and sn(n)] = q_prev(a,i,n);
        s.l(a,i,n)$[ia(i,a) and sn(n)] = s_prev(a,i,n);
        p.l(i,n)$sn(n) = p_prev(i,n);
        y.l(a,n)$sn(n) = y_prev(a,n);
        defFlow.m(a,i,n)$[ia(i,a) and sn(n)] = defFlow_m(a,i,n);
        defriskSet.m(a,n)$[not leafn(n)] = defriskSet_m(a,n);
        defSupplydemand.m(i,n)$sn(n) = defSupplydemand_m(i,n);
		break;
	);

	lastResidual = currentResidual;

	x_prev(a,i,n)$[ia(i,a) and sn(n)] = x.l(a,i,n);
	q_prev(a,i,n)$[ia(i,a) and sn(n)] = q.l(a,i,n);
	s_prev(a,i,n)$[ia(i,a) and sn(n)] = s.l(a,i,n);
	p_prev(i,n)$sn(n) = p.l(i,n);
	y_prev(a,n)$sn(n) = y.l(a,n);
	defFlow_m(a,i,n)$[ia(i,a) and sn(n)] = defFlow.m(a,i,n);
	defriskSet_m(a,n)$[not leafn(n)] = defriskSet.m(a,n);
	defSupplydemand_m(i,n)$sn(n) = defSupplydemand.m(i,n);

* update dual variable memory
	convexCombMem(a,n,mem)$sn(n) = convexCombMem(a,n,mem-1);
	convexCombMem(a,n,'m1')$sn(n) = y.l(a,n);


	iterationCount = iterationCount + 1;
);


* 	make sure we unfix all variables
	y.lo(a,n)$(not nt(n,'t0')) = (1 - lambda)*prob(n);
	y.up(a,n)$(not nt(n,'t0')) = (1 - lambda)*prob(n) + lambda*prob(n)/(1-alpha);

    x.up(a,i,n)$[ia(i,a) and sn(n)] = xup;
    x.lo(a,i,n)$[ia(i,a) and sn(n)] = xlo;
    q.up(a,i,n)$[ia(i,a) and sn(n)] = Cap(a,i,n);
    q.lo(a,i,n)$[ia(i,a) and sn(n)] = 0;
    s.up(a,i,n)$[ia(i,a) and sn(n)] = +inf;
    s.lo(a,i,n)$[ia(i,a) and sn(n)] = 0;
    p.up(i,n)$sn(n) = +inf;
    p.lo(i,n)$sn(n) = 0;


* solve the original model
embeddedcode reshop:
realAgent(a): min obj(a) x(a,i,n) q(a,i,n) s(a,i,n) defobj(a) defFlow(a,i,n)
riskAgent(a,n)$(not leafn(n)): max yobj(a,n) y(a,child)$(succ(n,child)) defsupp(a,n) defriskSet(a,n)
priceAgent(i,n)$(sn(n)): vi defSupplydemand(i,n) p(i,n)
equ: Nash(realAgent(a),riskAgent(a,n)$(not leafn(n)),priceAgent(i,n)$(sn(n)))
endembeddedcode

gasEnEqulibrium.optfile = 1;
solve gasEnEqulibrium using emp;

* now, see if we need convex combination for fix up

iterationCount = 0

* if model status is bad, we need convex combination step for fixup
if(gasEnEqulibrium.modelstat > 2,

while(iterationCount < iterationLimit,
* 	fix y and solve primal agent problem

	y.fx(a,n) = sum(mem,convexCombMem(a,n,mem) * memWeight(mem));

* solve primal model
embeddedcode reshop:
realAgent(a): min obj(a) x(a,i,n) q(a,i,n) s(a,i,n) defobj(a) defFlow(a,i,n)
priceAgent(i,n)$(sn(n)): vi defSupplydemand(i,n) p(i,n)
equ: Nash(realAgent(a),priceAgent(i,n)$(sn(n)))
endembeddedcode


	solve gasEnEqulibrium_RN using emp;

*   if bad things happen, exit the loop
	if(gasEnEqulibrium_RN.solvestat > 1 or gasEnEqulibrium_RN.modelstat > 2,
		break;
	);

* 	unfix y
	y.lo(a,n)$(not nt(n,'t0')) = (1 - lambda)*prob(n);
	y.up(a,n)$(not nt(n,'t0')) = (1 - lambda)*prob(n) + lambda*prob(n)/(1-alpha);

*   fix x q s
	x.fx(a,i,n) = x.l(a,i,n);
	q.fx(a,i,n) = q.l(a,i,n);
	s.fx(a,i,n) = s.l(a,i,n);
	p.fx(i,n) = p.l(i,n);

* solve dual problem
embeddedcode reshop:
riskAgent(a,n)$(not leafn(n)): max yobj(a,n) y(a,child)$(succ(n,child)) 
				defsupp(a,n) defriskSet(a,n)
equ: Nash(riskAgent(a,n)$(not leafn(n)))
endembeddedcode

	solve gasEnEqulibrium_Dual using emp;

*   check the residual 

embeddedcode reshop:
realAgent(a): min obj(a) x(a,i,n) q(a,i,n) s(a,i,n) defobj(a) defFlow(a,i,n)
riskAgent(a,n)$(not leafn(n)): max yobj(a,n) y(a,child)$(succ(n,child)) defsupp(a,n) defriskSet(a,n)
priceAgent(i,n)$(sn(n)): vi defSupplydemand(i,n) p(i,n)
equ: Nash(realAgent(a),riskAgent(a,n)$(not leafn(n)),priceAgent(i,n)$(sn(n)))
endembeddedcode

	gasEnEqulibrium.optfile = 2;
	solve gasEnEqulibrium using emp;

	currentResidual = meritTM;

	x.up(a,i,n) = xup;
	x.lo(a,i,n) = xlo;
	q.up(a,i,n) = Cap(a,i,n);
	q.lo(a,i,n) = 0;
	s.up(a,i,n) = +inf;
	s.lo(a,i,n) = 0;
	p.up(i,n) = +inf;
	p.lo(i,n) = 0;

*   if the residual is small enough, we break.
	if(gasEnEqulibrium.modelstat le 2,
*       use macro 
        x_prev(a,i,n)$[ia(i,a) and sn(n)] = x.l(a,i,n);
        q_prev(a,i,n)$[ia(i,a) and sn(n)] = q.l(a,i,n);
        s_prev(a,i,n)$[ia(i,a) and sn(n)] = s.l(a,i,n);
        p_prev(i,n)$sn(n) = p.l(i,n);
        y_prev(a,n)$sn(n) = y.l(a,n);
        defFlow_m(a,i,n)$[ia(i,a) and sn(n)] = defFlow.m(a,i,n);
        defriskSet_m(a,n)$[not leafn(n)] = defriskSet.m(a,n);
        defSupplydemand_m(i,n)$sn(n) = defSupplydemand.m(i,n);
		break;
	);

	if(iterationCount > 3 and currentResidual >= lastResidual,
*       use macro 
        q.l(a,i,n)$[ia(i,a) and sn(n)] = q_prev(a,i,n);
        s.l(a,i,n)$[ia(i,a) and sn(n)] = s_prev(a,i,n);
        p.l(i,n)$sn(n) = p_prev(i,n);
        y.l(a,n)$sn(n) = y_prev(a,n);
        defFlow.m(a,i,n)$[ia(i,a) and sn(n)] = defFlow_m(a,i,n);
        defriskSet.m(a,n)$[not leafn(n)] = defriskSet_m(a,n);
        defSupplydemand.m(i,n)$sn(n) = defSupplydemand_m(i,n);
		break;
	);

	lastResidual = currentResidual;

	x_prev(a,i,n)$[ia(i,a) and sn(n)] = x.l(a,i,n);
	q_prev(a,i,n)$[ia(i,a) and sn(n)] = q.l(a,i,n);
	s_prev(a,i,n)$[ia(i,a) and sn(n)] = s.l(a,i,n);
	p_prev(i,n)$sn(n) = p.l(i,n);
	y_prev(a,n)$sn(n) = y.l(a,n);
	defFlow_m(a,i,n)$[ia(i,a) and sn(n)] = defFlow.m(a,i,n);
	defriskSet_m(a,n)$[not leafn(n)] = defriskSet.m(a,n);
	defSupplydemand_m(i,n)$sn(n) = defSupplydemand.m(i,n);


* update dual variable memory
	convexCombMem(a,n,mem)$sn(n) = convexCombMem(a,n,mem-1);
	convexCombMem(a,n,'m1')$sn(n) = y.l(a,n);


	iterationCount = iterationCount + 1;
);


* 	make sure we unfix all variables
	y.lo(a,n)$(not nt(n,'t0')) = (1 - lambda)*prob(n);
	y.up(a,n)$(not nt(n,'t0')) = (1 - lambda)*prob(n) + lambda*prob(n)/(1-alpha);

    x.up(a,i,n)$[ia(i,a) and sn(n)] = xup;
    x.lo(a,i,n)$[ia(i,a) and sn(n)] = xlo;
    q.up(a,i,n)$[ia(i,a) and sn(n)] = Cap(a,i,n);
    q.lo(a,i,n)$[ia(i,a) and sn(n)] = 0;
    s.up(a,i,n)$[ia(i,a) and sn(n)] = +inf;
    s.lo(a,i,n)$[ia(i,a) and sn(n)] = 0;
    p.up(i,n)$sn(n) = +inf;
    p.lo(i,n)$sn(n) = 0;


* solve the original model
embeddedcode reshop:
realAgent(a): min obj(a) x(a,i,n) q(a,i,n) s(a,i,n) defobj(a) defFlow(a,i,n)
riskAgent(a,n)$(not leafn(n)): max yobj(a,n) y(a,child)$(succ(n,child)) defsupp(a,n) defriskSet(a,n)
priceAgent(i,n)$(sn(n)): vi defSupplydemand(i,n) p(i,n)
equ: Nash(realAgent(a),riskAgent(a,n)$(not leafn(n)),priceAgent(i,n)$(sn(n)))
endembeddedcode

gasEnEqulibrium.optfile = 1;
solve gasEnEqulibrium using emp;
);

display nt;