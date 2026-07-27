* file: algorithm_PD_CC_PATH.gms

* purpose: algorithm declaration


***** Algorithm : PD-CC-PATH c *****

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
put 'factorization_method lusol'/;
put 'nms_large_reference_factor 1e12'/;
put 'restart_limit 0'/;
putclose pathOptFile;

* path.op2 : limit start limit to 0 to allow
*            residual evaluation
file pathOptFile2 /path.op2/;
put pathOptFile2; 
put 'crash_perturb 0'/;
put 'crash_method none'/;
put 'major_iteration_limit 0'/;
putclose pathOptFile2;

gasEnEqulibrium_RN_social.optfile = 1;
gasEnEqulibrium_social.optfile = 1;

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
	convexCombMem(n,mem)
	memWeight(mem)
*   take record of the last solution
	x_prev(a,i,n)
	q_prev(a,i,n)
	s_prev(a,i,n)
	p_prev(i,n)
	y_prev(n)
	defFlow_m(a,i,n)
	defriskSet_m(n)
	defSupplydemand_m(i,n)
;
convexCombMem(n,mem)$(sn(n)) = prob(n);

memWeight('m1') = 0.5;
memWeight('m2') = 0.25;
memWeight('m3') = 0.25;

x_prev(a,i,n) = 0;
q_prev(a,i,n) = 0;
s_prev(a,i,n) = 0;
y_prev(n) = prob(n);
p_prev(i,n) = 0;

defFlow_m(a,i,n) = 0;
defriskSet_m(n) = 0;
defSupplydemand_m(i,n) = 0;

* set reshop as emp solver
option emp = reshop;

* hold fix to treate fixed variable
gasEnEqulibrium_RN_social.holdFixed = 1;
gasEnEqulibrium_Dual_social.holdFixed = 1;

while(iterationCount < iterationLimit,
* 	fix y and solve primal agent problem

	if(iterationCount eq 0,
		y_social.fx(n)$sn(n) = prob(n);
	else
		y_social.fx(n)$sn(n) = y_social.l(n);
	);

* solve primal problem
embeddedcode reshop:
realAgent(a): min obj(a) x(a,i,n) q(a,i,n) s(a,i,n) defobj_social(a) defFlow(a,i,n)
priceAgent(i,n)$(sn(n)): vi defSupplydemand(i,n) p(i,n)
equ: Nash(realAgent(a),priceAgent(i,n)$(sn(n)))
endembeddedcode


	solve gasEnEqulibrium_RN_social using emp;

*   if bad things happen, exit the loop
	if(gasEnEqulibrium_RN_social.solvestat > 1 or gasEnEqulibrium_RN_social.modelstat > 2,
		break;
	);

* 	unfix y
	y_social.lo(n)$(not nt(n,'t0')) = (1 - lambda)*prob(n);
	y_social.up(n)$(not nt(n,'t0')) = (1 - lambda)*prob(n) + lambda*prob(n)/(1-alpha);

*   fix x q s
	x.fx(a,i,n) = x.l(a,i,n);
	q.fx(a,i,n) = q.l(a,i,n);
	s.fx(a,i,n) = s.l(a,i,n);
	p.fx(i,n) = p.l(i,n);

*   solve dual problem
embeddedcode reshop:
riskAgent(n)$(not leafn(n)): max yobj_social(n) y_social(child)$(succ(n,child)) defsupp_social(n) defriskSet_social(n)
equ: Nash(riskAgent(n)$(not leafn(n)))
endembeddedcode

	solve gasEnEqulibrium_Dual_social using emp;

* 	unfix y
	y_social.lo(n)$(not nt(n,'t0')) = (1 - lambda)*prob(n);
	y_social.up(n)$(not nt(n,'t0')) = (1 - lambda)*prob(n) + lambda*prob(n)/(1-alpha);

	x.up(a,i,n)$[ia(i,a) and sn(n)] = xup;
	x.lo(a,i,n)$[ia(i,a) and sn(n)] = xlo;
	q.up(a,i,n)$[ia(i,a) and sn(n)] = Cap(a,i,n);
	q.up(a,i,n)$[not ia(i,a) or not sn(n)] = +inf;
	q.lo(a,i,n) = 0;
	s.up(a,i,n) = +inf;
	s.lo(a,i,n) = 0;
	p.up(i,n)$sn(n) = +inf;
	p.lo(i,n)$sn(n) = 0;

*   check the residual 

* solve the original model
embeddedcode reshop:
realAgent(a): min obj(a) x(a,i,n) q(a,i,n) s(a,i,n) defobj_social(a) defFlow(a,i,n)
riskAgent(n)$(not leafn(n)): max yobj_social(n) y_social(child)$(succ(n,child)) defsupp_social(n) defriskSet_social(n)
priceAgent(i,n)$(sn(n)): vi defSupplydemand(i,n) p(i,n)
equ: Nash(realAgent(a),riskAgent(n)$(not leafn(n)),priceAgent(i,n)$(sn(n)))
endembeddedcode

	defriskSet_social.m(n)$[not leafn(n)] = - defriskSet_social.m(n);

	gasEnEqulibrium_social.optfile = 2;
	solve gasEnEqulibrium_social using emp;

	currentResidual = gasEnEqulibrium_social.objval;

*   if the residual increases too much, we restore the last solution and exit
*   the loop
	if(iterationCount > 3 and currentResidual >= lastResidual,
		x.l(a,i,n)$[ia(i,a) and sn(n)] = x_prev(a,i,n);
        q.l(a,i,n)$[ia(i,a) and sn(n)] = q_prev(a,i,n);
        s.l(a,i,n)$[ia(i,a) and sn(n)] = s_prev(a,i,n);
        p.l(i,n)$sn(n) = p_prev(i,n);
        y_social.l(n)$sn(n) = y_prev(n);
        defFlow.m(a,i,n)$[ia(i,a) and sn(n)] = defFlow_m(a,i,n);
        defriskSet_social.m(n)$[not leafn(n)] = -defriskSet_m(n);
        defSupplydemand.m(i,n)$sn(n) = defSupplydemand_m(i,n);
		break;
	);


	lastResidual = currentResidual;

	x_prev(a,i,n)$[ia(i,a) and sn(n)] = x.l(a,i,n);
	q_prev(a,i,n)$[ia(i,a) and sn(n)] = q.l(a,i,n);
	s_prev(a,i,n)$[ia(i,a) and sn(n)] = s.l(a,i,n);
	p_prev(i,n)$sn(n) = p.l(i,n);
	y_prev(n)$sn(n) = y_social.l(n);
	defFlow_m(a,i,n)$[ia(i,a) and sn(n)] = defFlow.m(a,i,n);
	defriskSet_m(n)$[not leafn(n)] = defriskSet_social.m(n);
	defSupplydemand_m(i,n)$sn(n) = defSupplydemand.m(i,n);
* update dual variable memory
	convexCombMem(n,mem)$sn(n) = convexCombMem(n,mem-1);
	convexCombMem(n,'m1')$sn(n) = y_social.l(n);


	iterationCount = iterationCount + 1;
);

defriskSet_social.m(n)$[not leafn(n)] = - defriskSet_social.m(n);

* 	make sure we unfix all variables
y_social.lo(n)$(not nt(n,'t0')) = (1 - lambda)*prob(n);
y_social.up(n)$(not nt(n,'t0')) = (1 - lambda)*prob(n) + lambda*prob(n)/(1-alpha);

	x.up(a,i,n)$[ia(i,a) and sn(n)] = xup;
	x.lo(a,i,n)$[ia(i,a) and sn(n)] = xlo;
	q.up(a,i,n)$[ia(i,a) and sn(n)] = Cap(a,i,n);
	q.up(a,i,n)$[not ia(i,a) or not sn(n)] = +inf;
	q.lo(a,i,n) = 0;
	s.up(a,i,n) = +inf;
	s.lo(a,i,n) = 0;
	p.up(i,n)$sn(n) = +inf;
	p.lo(i,n)$sn(n) = 0;

* solve the original model
embeddedcode reshop:
realAgent(a): min obj(a) x(a,i,n) q(a,i,n) s(a,i,n) defobj_social(a) defFlow(a,i,n)
riskAgent(n)$(not leafn(n)): max yobj_social(n) y_social(child)$(succ(n,child)) defsupp_social(n) defriskSet_social(n)
priceAgent(i,n)$(sn(n)): vi defSupplydemand(i,n) p(i,n)
equ: Nash(realAgent(a),riskAgent(n)$(not leafn(n)),priceAgent(i,n)$(sn(n)))
endembeddedcode

gasEnEqulibrium_social.optfile = 1;
solve gasEnEqulibrium_social using emp;

* now, see if we need convex combination for fix up

iterationCount = 0;

* if model status is bad, we need convex combination step for fixup
if(gasEnEqulibrium_social.modelstat > 2,

while(iterationCount < iterationLimit,
* 	fix y and solve primal agent problem

	y_social.fx(n) = sum(mem,convexCombMem(n,mem) * memWeight(mem));


* solve primal problem
embeddedcode reshop:
realAgent(a): min obj(a) x(a,i,n) q(a,i,n) s(a,i,n) defobj_social(a) defFlow(a,i,n)
priceAgent(i,n)$(sn(n)): vi defSupplydemand(i,n) p(i,n)
equ: Nash(realAgent(a),priceAgent(i,n)$(sn(n)))
endembeddedcode


	solve gasEnEqulibrium_RN_social using emp;

*   if bad things happen, exit the loop
	if(gasEnEqulibrium_RN_social.solvestat > 1 or gasEnEqulibrium_RN_social.modelstat > 2,
		break;
	);

* 	unfix y
	y_social.lo(n)$(not nt(n,'t0')) = (1 - lambda)*prob(n);
	y_social.up(n)$(not nt(n,'t0')) = (1 - lambda)*prob(n) + lambda*prob(n)/(1-alpha);

*   fix x q s
	x.fx(a,i,n) = x.l(a,i,n);
	q.fx(a,i,n) = q.l(a,i,n);
	s.fx(a,i,n) = s.l(a,i,n);
	p.fx(i,n) = p.l(i,n);


*   solve dual problem
embeddedcode reshop:
riskAgent(n)$(not leafn(n)): max yobj_social(n) y_social(child)$(succ(n,child)) defsupp_social(n) defriskSet_social(n)
equ: Nash(riskAgent(n)$(not leafn(n)))
endembeddedcode

	solve gasEnEqulibrium_Dual_social using emp;

* 	unfix y
	y_social.lo(n)$(not nt(n,'t0')) = (1 - lambda)*prob(n);
	y_social.up(n)$(not nt(n,'t0')) = (1 - lambda)*prob(n) + lambda*prob(n)/(1-alpha);


	x.up(a,i,n)$[ia(i,a) and sn(n)] = xup;
	x.lo(a,i,n)$[ia(i,a) and sn(n)] = xlo;
	q.up(a,i,n)$[ia(i,a) and sn(n)] = Cap(a,i,n);
	q.up(a,i,n)$[not ia(i,a) or not sn(n)] = +inf;
	q.lo(a,i,n) = 0;
	s.up(a,i,n) = +inf;
	s.lo(a,i,n) = 0;
	p.up(i,n)$sn(n) = +inf;
	p.lo(i,n)$sn(n) = 0;

*   check the residual 

embeddedcode reshop:
realAgent(a): min obj(a) x(a,i,n) q(a,i,n) s(a,i,n) defobj_social(a) defFlow(a,i,n)
riskAgent(n)$(not leafn(n)): max yobj_social(n) y_social(child)$(succ(n,child)) defsupp_social(n) defriskSet_social(n)
priceAgent(i,n)$(sn(n)): vi defSupplydemand(i,n) p(i,n)
equ: Nash(realAgent(a),riskAgent(n)$(not leafn(n)),priceAgent(i,n)$(sn(n)))
endembeddedcode

	defriskSet_social.m(n)$[not leafn(n)] = - defriskSet_social.m(n);

	gasEnEqulibrium_social.optfile = 2;
	solve gasEnEqulibrium_social using emp;

	currentResidual = gasEnEqulibrium_social.objval;

*   if the residual increases too much, we restore the last solution and exit
*   the loop

	if(iterationCount > 3 and currentResidual >= lastResidual,
		x.l(a,i,n)$[ia(i,a) and sn(n)] = x_prev(a,i,n);
        q.l(a,i,n)$[ia(i,a) and sn(n)] = q_prev(a,i,n);
        s.l(a,i,n)$[ia(i,a) and sn(n)] = s_prev(a,i,n);
        p.l(i,n)$sn(n) = p_prev(i,n);
        y_social.l(n)$sn(n) = y_prev(n);
        defFlow.m(a,i,n)$[ia(i,a) and sn(n)] = defFlow_m(a,i,n);
        defriskSet_social.m(n)$[not leafn(n)] = -defriskSet_m(n);
        defSupplydemand.m(i,n)$sn(n) = defSupplydemand_m(i,n);
		break;
	);


	lastResidual = currentResidual;

	x_prev(a,i,n)$[ia(i,a) and sn(n)] = x.l(a,i,n);
	q_prev(a,i,n)$[ia(i,a) and sn(n)] = q.l(a,i,n);
	s_prev(a,i,n)$[ia(i,a) and sn(n)] = s.l(a,i,n);
	p_prev(i,n)$sn(n) = p.l(i,n);
	y_prev(n)$sn(n) = y_social.l(n);
	defFlow_m(a,i,n)$[ia(i,a) and sn(n)] = defFlow.m(a,i,n);
	defriskSet_m(n)$[not leafn(n)] = defriskSet_social.m(n);
	defSupplydemand_m(i,n)$sn(n) = defSupplydemand.m(i,n);


* update dual variable memory
	convexCombMem(n,mem)$sn(n) = convexCombMem(n,mem-1);
	convexCombMem(n,'m1')$sn(n) = y_social.l(n);


	iterationCount = iterationCount + 1;
);


defriskSet_social.m(n)$[not leafn(n)] = - defriskSet_social.m(n);

* 	make sure we unfix all variables
y_social.lo(n)$(not nt(n,'t0')) = (1 - lambda)*prob(n);
y_social.up(n)$(not nt(n,'t0')) = (1 - lambda)*prob(n) + lambda*prob(n)/(1-alpha);

	x.up(a,i,n)$[ia(i,a) and sn(n)] = xup;
	x.lo(a,i,n)$[ia(i,a) and sn(n)] = xlo;
	q.up(a,i,n)$[ia(i,a) and sn(n)] = Cap(a,i,n);
	q.up(a,i,n)$[not ia(i,a) or not sn(n)] = +inf;
	q.lo(a,i,n) = 0;
	s.up(a,i,n) = +inf;
	s.lo(a,i,n) = 0;
	p.up(i,n)$sn(n) = +inf;
	p.lo(i,n)$sn(n) = 0;


* solve the original model
embeddedcode reshop:
realAgent(a): min obj(a) x(a,i,n) q(a,i,n) s(a,i,n) defobj_social(a) defFlow(a,i,n)
riskAgent(n)$(not leafn(n)): max yobj_social(n) y_social(child)$(succ(n,child)) defsupp_social(n) defriskSet_social(n)
priceAgent(i,n)$(sn(n)): vi defSupplydemand(i,n) p(i,n)
equ: Nash(realAgent(a),riskAgent(n)$(not leafn(n)),priceAgent(i,n)$(sn(n)))
endembeddedcode

gasEnEqulibrium_social.optfile = 1;
solve gasEnEqulibrium_social using emp;
);

* fill in the social risk solution 

abort$(gasEnEqulibrium_social.modelstat > 2) 'social risk agent problem failed';


parameter
    y_normal_prev(a,n)
;

y.l(a,n)$sn(n) = y_social.l(n);
defriskSet.m(a,n)$[not leafn(n)] = defriskSet_social.m(n);



* * solve the original model
* embeddedcode reshop:
* realAgent(a): min obj(a) x(a,i,n) q(a,i,n) s(a,i,n) defobj(a) defFlow(a,i,n)
* riskAgent(a,n)$(not leafn(n)): max yobj(a,n) y(a,child)$(succ(n,child)) defsupp(a,n) defriskSet(a,n)
* priceAgent(i,n)$(sn(n)): vi defSupplydemand(i,n) p(i,n)
* equ: Nash(realAgent(a),riskAgent(a,n)$(not leafn(n)),priceAgent(i,n)$(sn(n)))
* endembeddedcode

* gasEnEqulibrium.optfile = 1;

* solve gasEnEqulibrium using emp;


* display n,nt;


****************************************
****************************************
****************************************
****************************************
****************************************
****************************************
****************************************
****************************************
****************************************
****************************************


parameter
	y_prev_orig(a,n)
	convexCombMem_orig(a,n,mem)
	defriskSet_m_orig(a,n)
;

* hold fix to treate fixed variable
gasEnEqulibrium_RN.holdFixed = 1;
gasEnEqulibrium_Dual.holdFixed = 1;

y.l(a,n)$sn(n) = y_social.l(n);
y_prev_orig(a,n) = y_social.l(n);
defriskSet.m(a,n)$[not leafn(n)] = defriskSet_social.m(n);
defriskSet_m_orig(a,n)$[not leafn(n)] = defriskSet_social.m(n);

convexCombMem_orig(a,n,'m1') = 0.5;
convexCombMem_orig(a,n,'m2') = 0.25;
convexCombMem_orig(a,n,'m3') = 0.25;

iterationCount = 0;

while(iterationCount < iterationLimit,
* 	fix y and solve primal agent problem

	y.fx(a,n)$sn(n) = y.l(a,n);

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

*   turn on all risk agents
	controlN(a,n) = yes; 

* stage 2 risk cost
	loop((aaa,nnn)$(sn(nnn) and nt(nnn,'t2')),
		iZero = 0;
		loop(child2$(succ(nnn,child2)),
			temp = costl(aaa,child2);
			if (temp = 0,
				iZero = iZero + 1;
			);
		);
* 5 children are all 0
		if (iZero = 5,
			controlN(aaa,nnn) = no;
		);
	); 

* stage 1 risk cost
	loop((aaa,nnn)$(sn(nnn) and nt(nnn,'t1')),
		iZero = 0;
		loop(child2$(succ(nnn,child2)),
			temp=stage2Cost(aaa,child2);
			if (temp = 0,
				iZero = iZero + 1;
			);
		);
* 5 children are all 0
		if (iZero = 5,
			controlN(aaa,nnn) = no;
		);
	); 

* stage 1 risk cost
	loop((aaa,nnn)$(sn(nnn) and nt(nnn,'t0')),
		iZero = 0;
		loop(child2$(succ(nnn,child2)),
			temp=stage1Cost(aaa,child2);
			if (temp = 0,
				iZero = iZero + 1;
			);
		);
* 5 children are all 0
		if (iZero = 5,
			controlN(aaa,nnn) = no;
		);
	); 


	controlN(a,n)$(leafn(n)) = no;

*   solve dual problem
embeddedcode reshop:
riskAgent(a,n)$(controlN(a,n)): max yobj(a,n) y(a,child)$(succ(n,child)) 
				defsupp(a,n) defriskSet(a,n)
equ: Nash(riskAgent(a,n)$(controlN(a,n)))
endembeddedcode

	solve gasEnEqulibrium_Dual using emp;

* 	unfix y
	y.lo(a,n)$(not nt(n,'t0')) = (1 - lambda)*prob(n);
	y.up(a,n)$(not nt(n,'t0')) = (1 - lambda)*prob(n) + lambda*prob(n)/(1-alpha);

	x.up(a,i,n)$[ia(i,a) and sn(n)] = xup;
	x.lo(a,i,n)$[ia(i,a) and sn(n)] = xlo;
	q.up(a,i,n)$[ia(i,a) and sn(n)] = Cap(a,i,n);
	q.up(a,i,n)$[not ia(i,a) or not sn(n)] = +inf;
	q.lo(a,i,n) = 0;
	s.up(a,i,n) = +inf;
	s.lo(a,i,n) = 0;
	p.up(i,n)$sn(n) = +inf;
	p.lo(i,n)$sn(n) = 0;

*   check the residual 

	currentResidual = meritTM;

*   if the residual increases too much, we restore the last solution and exit
*   the loop
	if(iterationCount > 3 and currentResidual >= lastResidual,
		x.l(a,i,n)$[ia(i,a) and sn(n)] = x_prev(a,i,n);
        q.l(a,i,n)$[ia(i,a) and sn(n)] = q_prev(a,i,n);
        s.l(a,i,n)$[ia(i,a) and sn(n)] = s_prev(a,i,n);
        p.l(i,n)$sn(n) = p_prev(i,n);
        y.l(a,n)$sn(n) = y_prev_orig(a,n);
        defFlow.m(a,i,n)$[ia(i,a) and sn(n)] = defFlow_m(a,i,n);
        defriskSet.m(a,n)$[not leafn(n)] = defriskSet_m_orig(a,n);
        defSupplydemand.m(i,n)$sn(n) = defSupplydemand_m(i,n);
		break;
	);


	lastResidual = currentResidual;

	x_prev(a,i,n)$[ia(i,a) and sn(n)] = x.l(a,i,n);
	q_prev(a,i,n)$[ia(i,a) and sn(n)] = q.l(a,i,n);
	s_prev(a,i,n)$[ia(i,a) and sn(n)] = s.l(a,i,n);
	p_prev(i,n)$sn(n) = p.l(i,n);
	y_prev_orig(a,n)$sn(n) = y.l(a,n);
	defFlow_m(a,i,n)$[ia(i,a) and sn(n)] = defFlow.m(a,i,n);
	defriskSet_m_orig(a,n)$[not leafn(n)] = defriskSet.m(a,n);
	defSupplydemand_m(i,n)$sn(n) = defSupplydemand.m(i,n);
* update dual variable memory
	convexCombMem_orig(a,n,mem)$sn(n) = convexCombMem_orig(a,n,mem-1);
	convexCombMem_orig(a,n,'m1')$sn(n) = y.l(a,n);


	iterationCount = iterationCount + 1;
);

defriskSet.m(a,n)$[not leafn(n)] = - defriskSet.m(a,n);

* 	make sure we unfix all variables
y.lo(a,n)$(not nt(n,'t0')) = (1 - lambda)*prob(n);
y.up(a,n)$(not nt(n,'t0')) = (1 - lambda)*prob(n) + lambda*prob(n)/(1-alpha);

	x.up(a,i,n)$[ia(i,a) and sn(n)] = xup;
	x.lo(a,i,n)$[ia(i,a) and sn(n)] = xlo;
	q.up(a,i,n)$[ia(i,a) and sn(n)] = Cap(a,i,n);
	q.up(a,i,n)$[not ia(i,a) or not sn(n)] = +inf;
	q.lo(a,i,n) = 0;
	s.up(a,i,n) = +inf;
	s.lo(a,i,n) = 0;
	p.up(i,n)$sn(n) = +inf;
	p.lo(i,n)$sn(n) = 0;

controlN(a,n) = yes;
controlN(a,n)$(leafn(n)) = no;

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

	y.fx(a,n) = sum(mem,convexCombMem_orig(a,n,mem) * memWeight(mem));


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

*   turn on all risk agents
	controlN(a,n) = yes; 

* stage 2 risk cost
	loop((aaa,nnn)$(sn(nnn) and nt(nnn,'t2')),
		iZero = 0;
		loop(child2$(succ(nnn,child2)),
			temp = costl(aaa,child2);
			if (temp = 0,
				iZero = iZero + 1;
			);
		);
* 5 children are all 0
		if (iZero = 5,
			controlN(aaa,nnn) = no;
		);
	); 

* stage 1 risk cost
	loop((aaa,nnn)$(sn(nnn) and nt(nnn,'t1')),
		iZero = 0;
		loop(child2$(succ(nnn,child2)),
			temp=stage2Cost(aaa,child2);
			if (temp = 0,
				iZero = iZero + 1;
			);
		);
* 5 children are all 0
		if (iZero = 5,
			controlN(aaa,nnn) = no;
		);
	); 

* stage 1 risk cost
	loop((aaa,nnn)$(sn(nnn) and nt(nnn,'t0')),
		iZero = 0;
		loop(child2$(succ(nnn,child2)),
			temp=stage1Cost(aaa,child2);
			if (temp = 0,
				iZero = iZero + 1;
			);
		);
* 5 children are all 0
		if (iZero = 5,
			controlN(aaa,nnn) = no;
		);
	); 

	controlN(a,n)$(leafn(n)) = no;

*   solve dual problem
embeddedcode reshop:
riskAgent(a,n)$(controlN(a,n)): max yobj(a,n) y(a,child)$(succ(n,child)) 
				defsupp(a,n) defriskSet(a,n)
equ: Nash(riskAgent(a,n)$(controlN(a,n)))
endembeddedcode

	solve gasEnEqulibrium_Dual using emp;

* 	unfix y
	y.lo(a,n)$(not nt(n,'t0')) = (1 - lambda)*prob(n);
	y.up(a,n)$(not nt(n,'t0')) = (1 - lambda)*prob(n) + lambda*prob(n)/(1-alpha);


	x.up(a,i,n)$[ia(i,a) and sn(n)] = xup;
	x.lo(a,i,n)$[ia(i,a) and sn(n)] = xlo;
	q.up(a,i,n)$[ia(i,a) and sn(n)] = Cap(a,i,n);
	q.up(a,i,n)$[not ia(i,a) or not sn(n)] = +inf;
	q.lo(a,i,n) = 0;
	s.up(a,i,n) = +inf;
	s.lo(a,i,n) = 0;
	p.up(i,n)$sn(n) = +inf;
	p.lo(i,n)$sn(n) = 0;

*   check the residual 

	currentResidual = meritTM;

	if(iterationCount > 3 and currentResidual >= lastResidual,
*       use macro 
		x.l(a,i,n)$[ia(i,a) and sn(n)] = x_prev(a,i,n);
        q.l(a,i,n)$[ia(i,a) and sn(n)] = q_prev(a,i,n);
        s.l(a,i,n)$[ia(i,a) and sn(n)] = s_prev(a,i,n);
        p.l(i,n)$sn(n) = p_prev(i,n);
        y.l(a,n)$sn(n) = y_prev_orig(a,n);
        defFlow.m(a,i,n)$[ia(i,a) and sn(n)] = defFlow_m(a,i,n);
        defriskSet.m(a,n)$[not leafn(n)] = defriskSet_m_orig(a,n);
        defSupplydemand.m(i,n)$sn(n) = defSupplydemand_m(i,n);
		break;
	);

	lastResidual = currentResidual;

	x_prev(a,i,n)$[ia(i,a) and sn(n)] = x.l(a,i,n);
	q_prev(a,i,n)$[ia(i,a) and sn(n)] = q.l(a,i,n);
	s_prev(a,i,n)$[ia(i,a) and sn(n)] = s.l(a,i,n);
	p_prev(i,n)$sn(n) = p.l(i,n);
	y_prev_orig(a,n)$sn(n) = y.l(a,n);
	defFlow_m(a,i,n)$[ia(i,a) and sn(n)] = defFlow.m(a,i,n);
	defriskSet_m_orig(a,n)$[not leafn(n)] = defriskSet.m(a,n);
	defSupplydemand_m(i,n)$sn(n) = defSupplydemand.m(i,n);


* update dual variable memory
	convexCombMem_orig(a,n,mem)$sn(n) = convexCombMem_orig(a,n,mem-1);
	convexCombMem_orig(a,n,'m1')$sn(n) = y.l(a,n);


	iterationCount = iterationCount + 1;
);


defriskSet.m(a,n)$[not leafn(n)] = - defriskSet.m(a,n);

* 	make sure we unfix all variables
y.lo(a,n)$(not nt(n,'t0')) = (1 - lambda)*prob(n);
y.up(a,n)$(not nt(n,'t0')) = (1 - lambda)*prob(n) + lambda*prob(n)/(1-alpha);

	x.up(a,i,n)$[ia(i,a) and sn(n)] = xup;
	x.lo(a,i,n)$[ia(i,a) and sn(n)] = xlo;
	q.up(a,i,n)$[ia(i,a) and sn(n)] = Cap(a,i,n);
	q.up(a,i,n)$[not ia(i,a) or not sn(n)] = +inf;
	q.lo(a,i,n) = 0;
	s.up(a,i,n) = +inf;
	s.lo(a,i,n) = 0;
	p.up(i,n)$sn(n) = +inf;
	p.lo(i,n)$sn(n) = 0;

controlN(a,n) = yes;
controlN(a,n)$(leafn(n)) = no;

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
