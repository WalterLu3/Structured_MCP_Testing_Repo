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
	alternativeResidual
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
alternativeResidual = +inf;

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
*   take record of the last solution
	x_best(a,i,n)
	q_best(a,i,n)
	s_best(a,i,n)
	y_best(a,n)
	p_best(i,n)
	defFlow_m_best(a,i,n)
	defriskSet_m_best(a,n)
	defSupplydemand_m_best(i,n)
*   take record of the temporary solution
	x_temp(a,i,n)
	q_temp(a,i,n)
	s_temp(a,i,n)
	y_temp(a,n)
	p_temp(i,n)
	defFlow_m_temp(a,i,n)
	defriskSet_m_temp(a,n)
	defSupplydemand_m_temp(i,n)
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


	x.up(a,i,n) = xup;
	x.lo(a,i,n) = xlo;
	q.up(a,i,n) = Cap(a,i,n);
	q.lo(a,i,n) = 0;
	s.up(a,i,n) = +inf;
	s.lo(a,i,n) = 0;
	p.up(i,n) = +inf;
	p.lo(i,n) = 0;

*   check the residual 

	currentResidual = meritTM;

	x_temp(a,i,n)$[ia(i,a) and sn(n)] = x.l(a,i,n);
	q_temp(a,i,n)$[ia(i,a) and sn(n)] = q.l(a,i,n);
	s_temp(a,i,n)$[ia(i,a) and sn(n)] = s.l(a,i,n);
	p_temp(i,n)$sn(n) = p.l(i,n);
	y_temp(a,n)$sn(n) = y.l(a,n);
	defFlow_m_temp(a,i,n)$[ia(i,a) and sn(n)] = defFlow.m(a,i,n);
	defriskSet_m_temp(a,n)$[not leafn(n)] = defriskSet.m(a,n);
	defSupplydemand_m_temp(i,n)$sn(n) = defSupplydemand.m(i,n);

*   if the residual gots worse, convex combination
	if(currentResidual >= lastResidual,
*       use macro
     x.l(a,i,n)$[ia(i,a) and sn(n)] = lineStep*x_prev(a,i,n) + (1-lineStep)*x.l(a,i,n);
     q.l(a,i,n)$[ia(i,a) and sn(n)] = lineStep*q_prev(a,i,n) + (1-lineStep)*q.l(a,i,n);
     s.l(a,i,n)$[ia(i,a) and sn(n)] = lineStep*s_prev(a,i,n) + (1-lineStep)*s.l(a,i,n);
     p.l(i,n)$sn(n) = lineStep*p_prev(i,n) + (1-lineStep)* p.l(i,n);
     y.l(a,n)$sn(n) = lineStep*y_prev(a,n) + (1-lineStep)* y.l(a,n);
     defFlow.m(a,i,n)$[ia(i,a) and sn(n)] = lineStep*defFlow_m(a,i,n) + (1-lineStep)*defFlow.m(a,i,n);
     defriskSet.m(a,n)$[not leafn(n)] = lineStep*defriskSet_m(a,n) + (1-lineStep)*defriskSet.m(a,n);
     defSupplydemand.m(i,n)$sn(n) = lineStep*defSupplydemand_m(i,n) + (1-lineStep)*defSupplydemand.m(i,n);
	 
	);

	alternativeResidual =  meritTM;

	if (currentResidual <= alternativeResidual,
     x.l(a,i,n)$[ia(i,a) and sn(n)] = x_temp(a,i,n);
     q.l(a,i,n)$[ia(i,a) and sn(n)] = q_temp(a,i,n);
     s.l(a,i,n)$[ia(i,a) and sn(n)] = s_temp(a,i,n);
     p.l(i,n)$sn(n) = p_temp(i,n);
     y.l(a,n)$sn(n) = y_temp(a,n);
     defFlow.m(a,i,n)$[ia(i,a) and sn(n)] = defFlow_m_temp(a,i,n);
     defriskSet.m(a,n)$[not leafn(n)] = defriskSet_m_temp(a,n);
     defSupplydemand.m(i,n)$sn(n) =	defSupplydemand_m_temp(i,n);
	 else
	 	currentResidual = alternativeResidual;
	);

	if(currentResidual >= lastResidual,
		notImproveCount = notImproveCount + 1;
	);

*   not improving for to long, we break
	if (notImproveCount > 10,
		break;
	);

*	currentResidual = meritTM;
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
q.lo(a,i,n)$[ia(i,a) and sn(n)] = 0;
s.up(a,i,n)$[ia(i,a) and sn(n)] = +inf;
s.lo(a,i,n)$[ia(i,a) and sn(n)] = 0;
p.up(i,n)$sn(n) = +inf;
p.lo(i,n)$sn(n) = 0;

y.lo(a,n)$(not nt(n,'t0')) = (1 - lambda)*prob(n);
y.up(a,n)$(not nt(n,'t0')) = (1 - lambda)*prob(n) + lambda*prob(n)/(1-alpha);

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
