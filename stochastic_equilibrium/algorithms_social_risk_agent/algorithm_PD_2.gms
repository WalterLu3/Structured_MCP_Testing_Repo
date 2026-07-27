* file: algorithm_PD_PATH.gms

* purpose: algorithm declaration


***** Algorithm : PD followed by PATH solve *****

* option file reshop.opt and path.opt to disable crash method.
* We do this because we want to use the accurate starting info.
* Other options are set based on Jiajie's file

* reshop.opt option file
file reshopOptFile /reshop.opt/;
put reshopOptFile;
put 'subsolveropt 1'/;
putclose reshopOptFile;

file reshopOptFile2 /reshop.op2/;
put reshopOptFile2;
put 'subsolveropt 2'/;
putclose reshopOptFile2;


* path.opt : disable crash method
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
;
iterationCount = 0;
currentResidual = 0;
lastResidual = +inf;
minResidual = +inf;


set
	iter /ii1*ii%iterationLimit%/
	dum /'dummy'/
	dum2 /'pd-time'/
	dum3 /'path-time'/
;

parameter
*   take record of the last solution
	residual(iter)
	x_prev(a,i,n)
	q_prev(a,i,n)
	s_prev(a,i,n)
	y_prev(n)
	p_prev(i,n)
	defFlow_m(a,i,n)
	defriskSet_m(n)
	defSupplydemand_m(i,n)
*   take record of the last solution
	x_best(a,i,n)
	q_best(a,i,n)
	s_best(a,i,n)
	y_best(n)
	p_best(i,n)
	defFlow_m_best(a,i,n)
	defriskSet_m_best(n)
	defSupplydemand_m_best(i,n)
	reportResidual(dum)
	reportPDTime(dum2)
	reportPATHTime(dum3)
;
residual(iter) = 0;
x_prev(a,i,n) = 0;
q_prev(a,i,n) = 0;
s_prev(a,i,n) = 0;
y_prev(n) = prob(n);
p_prev(i,n) = 0;

defFlow_m(a,i,n) = 0;
defriskSet_m(n) = 0;
defSupplydemand_m(i,n) = 0;

x_best(a,i,n) = 0;
q_best(a,i,n) = 0;
s_best(a,i,n) = 0;
y_best(n) = 0;
p_best(i,n) = 0;
defFlow_m_best(a,i,n) = 0;
defriskSet_m_best(n) = 0;
defSupplydemand_m_best(i,n) = 0;

* set reshop as emp solver
option emp = reshop;

* hold fix to treate fixed variable
gasEnEqulibrium_RN.holdFixed = 1;
gasEnEqulibrium_Dual.holdFixed = 1;

while(iterationCount < iterationLimit,
* 	fix y and solve primal agent problem

	if(iterationCount eq 0,
		y.fx(n)$sn(n) = prob(n);
	else
		y.fx(n)$sn(n) = y.l(n);
	);
	
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
	y.lo(n)$(not nt(n,'t0')) = (1 - lambda)*prob(n);
	y.up(n)$(not nt(n,'t0')) = (1 - lambda)*prob(n) + lambda*prob(n)/(1-alpha);

*   fix x q s
	x.fx(a,i,n) = x.l(a,i,n);
	q.fx(a,i,n) = q.l(a,i,n);
	s.fx(a,i,n) = s.l(a,i,n);
	p.fx(i,n) = p.l(i,n);

*   turn on all risk agents (for zero detection)
	controlN(n) = yes; 

	controlN(n)$(leafn(n)) = no;
	
*   solve dual problem
embeddedcode reshop:
riskAgent(n)$(controlN(n)): max yobj(n) y(child)$(succ(n,child)) 
				defsupp(n) defriskSet(n)
equ: Nash(riskAgent(n)$(controlN(n)))
endembeddedcode

	solve gasEnEqulibrium_Dual using emp;

* unfix variables
	y.lo(n)$(not nt(n,'t0')) = (1 - lambda)*prob(n);
	y.up(n)$(not nt(n,'t0')) = (1 - lambda)*prob(n) + lambda*prob(n)/(1-alpha);

	x.up(a,i,n) = xup;
	x.lo(a,i,n) = xlo;
	q.up(a,i,n) = Cap(a,i,n);
	q.lo(a,i,n) = 0;
	s.up(a,i,n) = +inf;
	s.lo(a,i,n) = 0;
	p.up(i,n) = +inf;
	p.lo(i,n) = 0;


* solve the original model
embeddedcode reshop:
realAgent(a): min obj(a) x(a,i,n) q(a,i,n) s(a,i,n) defobj(a) defFlow(a,i,n)
riskAgent(n)$(not leafn(n)): max yobj(n) y(child)$(succ(n,child)) defsupp(n) defriskSet(n)
priceAgent(i,n)$(sn(n)): vi defSupplydemand(i,n) p(i,n)
equ: Nash(realAgent(a),riskAgent(n)$(not leafn(n)),priceAgent(i,n)$(sn(n)))
endembeddedcode

toTimes = 0.5;

defriskSet.m(n)$[not leafn(n)] = - defriskSet.m(n);

gasEnEqulibrium.optfile = 2;
solve gasEnEqulibrium using emp;




if ( gasEnEqulibrium.solvestat <= 2,
    break;
);


	iterationCount = iterationCount + 1;
);

    defriskSet.m(n)$[not leafn(n)] = - defriskSet.m(n);
*   This should be eliminated later
*   What I found is that reshop flip the sign of muliplier
*   for defRiskSet
*	reportPDTime('pd-time') = timeelapsed;
 
* 	make sure we unfix y as the algorithm can exit after primal step
	x.up(a,i,n) = xup;
	x.lo(a,i,n) = xlo;
	q.up(a,i,n) = Cap(a,i,n);
	q.lo(a,i,n) = 0;
	s.up(a,i,n) = +inf;
	s.lo(a,i,n) = 0;
	p.up(i,n) = +inf;
	p.lo(i,n) = 0;

	y.lo(n)$(not nt(n,'t0')) = (1 - lambda)*prob(n);
	y.up(n)$(not nt(n,'t0')) = (1 - lambda)*prob(n) + lambda*prob(n)/(1-alpha);

*	x.l(a,i,n)$[ia(i,a) and sn(n)] = x_best(a,i,n);
*	q.l(a,i,n)$[ia(i,a) and sn(n)] = q_best(a,i,n);
*	s.l(a,i,n)$[ia(i,a) and sn(n)] = s_best(a,i,n);
*	y.l(a,n)$sn(n) = y_best(a,n);
*	p.l(i,n)$sn(n) = p_best(i,n);
*	defFlow.m(a,i,n)$[ia(i,a) and sn(n)] = defFlow_m_best(a,i,n);
*	defriskSet.m(a,n)$[not leafn(n)] = -defriskSet_m_best(a,n);
*	defSupplydemand.m(i,n)$sn(n) = defSupplydemand_m_best(i,n);

controlN(n) = yes;
controlN(n)$(leafn(n)) = no;

* solve the original model
embeddedcode reshop:
realAgent(a): min obj(a) x(a,i,n) q(a,i,n) s(a,i,n) defobj(a) defFlow(a,i,n)
riskAgent(n)$(not leafn(n)): max yobj(n) y(child)$(succ(n,child)) defsupp(n) defriskSet(n)
priceAgent(i,n)$(sn(n)): vi defSupplydemand(i,n) p(i,n)
equ: Nash(realAgent(a),riskAgent(n)$(not leafn(n)),priceAgent(i,n)$(sn(n)))
endembeddedcode

toTimes = toSet;

gasEnEqulibrium.optfile = 2;
solve gasEnEqulibrium using emp;

