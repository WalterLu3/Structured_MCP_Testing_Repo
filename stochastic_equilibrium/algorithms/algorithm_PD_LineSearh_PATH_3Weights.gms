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

gasEnEqulibrium_RN.optfile = 1;
gasEnEqulibrium.optfile = 1;

scalar 
	iterationCount     count the number of iterations
	currentResidual    record current residual
	lastResidual       record last residual
	minResidual        record minimized residual
	lineStep
	notImproveCount
;

notImproveCount = 0;
lineStep = 0.5;
iterationCount = 0;
currentResidual = 0;
lastResidual = +inf;
minResidual = +inf;

set
	mem /m1*m3/
	varName /'xVar', 'qVar', 'sVar', 'pVar', 
			 'defFlowM', 'defrisketM', 'defSupplyDemandM'/
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
*	second last
	x_old(a,i,n)
	q_old(a,i,n)
	s_old(a,i,n)
	p_old(i,n)
	y_old(a,n)
	defFlow_m_old(a,i,n)
	defriskSet_m_old(a,n)
	defSupplydemand_m_old(i,n)
*   take record of the last solution
	x_best(a,i,n)
	q_best(a,i,n)
	s_best(a,i,n)
	y_best(a,n)
	p_best(i,n)
	defFlow_m_best(a,i,n)
	defriskSet_m_best(a,n)
	defSupplydemand_m_best(i,n)
;

* memWeight('m1') = 0.5;
* memWeight('m2') = 0.25;
* memWeight('m3') = 0.25;

x_prev(a,i,n) = 0;
q_prev(a,i,n) = 0;
s_prev(a,i,n) = 0;
y_prev(a,n) = prob(n);
p_prev(i,n) = 0;
defFlow_m(a,i,n) = 0;
defriskSet_m(a,n) = 0;
defSupplydemand_m(i,n) = 0;

x_old(a,i,n) = 0;
q_old(a,i,n) = 0;
s_old(a,i,n) = 0;
p_old(i,n) = 0;
y_old(a,n) = prob(n);
defFlow_m_old(a,i,n) = 0;
defriskSet_m_old(a,n) = 0;
defSupplydemand_m_old(i,n) = 0;

x_best(a,i,n) = 0;
q_best(a,i,n) = 0;
s_best(a,i,n) = 0;
y_best(a,n) = 0;
p_best(i,n) = 0;
defFlow_m_best(a,i,n) = 0;
defriskSet_m_best(a,n) = 0;
defSupplydemand_m_best(i,n) = 0;

y.l(a,n) = prob(n);
* set reshop as emp solver
option emp = reshop;

* hold fix to treate fixed variable
gasEnEqulibrium_RN.holdFixed = 1;
gasEnEqulibrium_Dual.holdFixed = 1;

iterationCount = 0;

* Do CC step unconditionally



while(iterationCount < iterationLimit,
* 	fix y and solve primal agent problem	
	y.fx(a,n) = y.l(a,n);

* solve primal problem
embeddedcode reshop:
realAgent(a): min obj(a) x(a,i,n) q(a,i,n) s(a,i,n) defobj(a) defFlow(a,i,n)
priceAgent(i,n)$(sn(n)): vi defSupplydemand(i,n) p(i,n)
equ: Nash(realAgent(a),priceAgent(i,n)$(sn(n)))
endembeddedcode

solve gasEnEqulibrium_RN using emp;

abort$(gasEnEqulibrium_RN.modelstat > 2 or gasEnEqulibrium_RN.solveStat > 1 ) '##################### gasEnEqulibrium_RN fails to solve the model to optimality';

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
riskAgent(a,n)$(controlN(a,n)): max yobj(a,n) y(a,child)$(succ(n,child)) 
				defsupp(a,n) defriskSet(a,n)
equ: Nash(riskAgent(a,n)$(controlN(a,n)))
endembeddedcode

	solve gasEnEqulibrium_Dual using emp;

abort$(gasEnEqulibrium_Dual.modelstat > 2 or gasEnEqulibrium_Dual.solveStat > 1 ) '##################### gasEnEqulibrium_Dual fails to solve the model to optimality';

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

*   if the residual gots worse, convex combination
	if(currentResidual >= lastResidual,
*       use macro
		x.l(a,i,n)$[ia(i,a) and sn(n)] = 0.1*x_old(a,i,n) + 0.4*x_prev(a,i,n) + (0.5)*x.l(a,i,n);
		q.l(a,i,n)$[ia(i,a) and sn(n)] = 0.1*q_old(a,i,n) + 0.4*q_prev(a,i,n) + (0.5)*q.l(a,i,n);
		s.l(a,i,n)$[ia(i,a) and sn(n)] = 0.1*s_old(a,i,n) + 0.4*s_prev(a,i,n) + (0.5)*s.l(a,i,n);
		p.l(i,n)$sn(n) = 0.1*p_old(i,n) + 0.4*p_prev(i,n) + (0.5)*p.l(i,n);
		y.l(a,n)$sn(n) = 0.1*y_old(a,n) + 0.4*y_prev(a,n) + (0.5)*y.l(a,n);
		defFlow.m(a,i,n)$[ia(i,a) and sn(n)] = 0.1*defFlow_m_old(a,i,n) + 0.4*defFlow_m(a,i,n) + (0.5)*defFlow.m(a,i,n);
		defriskSet.m(a,n)$[not leafn(n)] = 0.1*defriskSet_m_old(a,n) + 0.4*defriskSet_m(a,n) + (0.5)*defriskSet.m(a,n);
		defSupplydemand.m(i,n)$sn(n) = 0.1*defSupplydemand_m_old(i,n) + 0.4*defSupplydemand_m(i,n) + (0.5)*defSupplydemand.m(i,n);
		notImproveCount = notImproveCount + 1;
	);

*   not improving for to long, we break
	if (notImproveCount > 10,
		break;
	);

*	currentResidual = meritTM;
    currentResidual = meritTM;
	lastResidual = currentResidual;

*   keep track of best point
	if (currentResidual < minResidual,
		minResidual = currentResidual;
		x_best(a,i,n)$[ia(i,a) and sn(n)] = x.l(a,i,n);
		q_best(a,i,n)$[ia(i,a) and sn(n)] = q.l(a,i,n);
		s_best(a,i,n)$[ia(i,a) and sn(n)] = s.l(a,i,n);
		y_best(a,n)$sn(n) = y.l(a,n);
		p_best(i,n)$sn(n) = p.l(i,n);
		defFlow_m_best(a,i,n)$[ia(i,a) and sn(n)] = defFlow.m(a,i,n);
		defriskSet_m_best(a,n)$[not leafn(n)] = defriskSet.m(a,n);
		defSupplydemand_m_best(i,n)$sn(n) = defSupplydemand.m(i,n);
	);

	x_old(a,i,n)$[ia(i,a) and sn(n)] = x_prev(a,i,n);
	q_old(a,i,n)$[ia(i,a) and sn(n)] = q_prev(a,i,n);
	s_old(a,i,n)$[ia(i,a) and sn(n)] = s_prev(a,i,n);
	p_old(i,n)$sn(n) = p_prev(i,n);
	y_old(a,n)$sn(n) = y_prev(a,n);
	defFlow_m_old(a,i,n)$[ia(i,a) and sn(n)] =defFlow_m(a,i,n);
	defriskSet_m_old(a,n)$[not leafn(n)] = defriskSet_m(a,n);
	defSupplydemand_m_old(i,n)$sn(n) = defSupplydemand_m(i,n);

	x_prev(a,i,n)$[ia(i,a) and sn(n)] = x.l(a,i,n);
	q_prev(a,i,n)$[ia(i,a) and sn(n)] = q.l(a,i,n);
	s_prev(a,i,n)$[ia(i,a) and sn(n)] = s.l(a,i,n);
	p_prev(i,n)$sn(n) = p.l(i,n);
	y_prev(a,n)$sn(n) = y.l(a,n);
	defFlow_m(a,i,n)$[ia(i,a) and sn(n)] = defFlow.m(a,i,n);
	defriskSet_m(a,n)$[not leafn(n)] = defriskSet.m(a,n);
	defSupplydemand_m(i,n)$sn(n) = defSupplydemand.m(i,n);

	iterationCount = iterationCount + 1;
);

x.l(a,i,n)$[ia(i,a) and sn(n)] = x_best(a,i,n);
q.l(a,i,n)$[ia(i,a) and sn(n)] = q_best(a,i,n);
s.l(a,i,n)$[ia(i,a) and sn(n)] = s_best(a,i,n);
y.l(a,n)$sn(n) = y_best(a,n);
p.l(i,n)$sn(n) = p_best(i,n);
defFlow.m(a,i,n)$[ia(i,a) and sn(n)] = defFlow_m_best(a,i,n);
* note that we need negative sign here
defriskSet.m(a,n)$[not leafn(n)] = -defriskSet_m_best(a,n);
defSupplydemand.m(i,n)$sn(n) = defSupplydemand_m_best(i,n);

* 	make sure we unfix all variables
	x.up(a,i,n)$[ia(i,a) and sn(n)] = xup;
	x.lo(a,i,n)$[ia(i,a) and sn(n)] = xlo;
	q.up(a,i,n)$[ia(i,a) and sn(n)] = Cap(a,i,n);
	q.up(a,i,n)$[not ia(i,a) or not sn(n)] = +inf;
	q.lo(a,i,n) = 0;
	s.up(a,i,n) = +inf;
	s.lo(a,i,n) = 0;
	p.up(i,n)$sn(n) = +inf;
	p.lo(i,n)$sn(n) = 0;

y.lo(a,n)$(not nt(n,'t0')) = (1 - lambda)*prob(n);
y.up(a,n)$(not nt(n,'t0')) = (1 - lambda)*prob(n) + lambda*prob(n)/(1-alpha);


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
