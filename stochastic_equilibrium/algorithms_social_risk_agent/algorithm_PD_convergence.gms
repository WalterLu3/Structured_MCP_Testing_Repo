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
	iter /ii1*ii%iterationLimit%/;

parameter
*   take record of the last solution
	residual(iter)
	x_prev(a,i,n)
	q_prev(a,i,n)
	s_prev(a,i,n)
	y_prev(a,n)
	p_prev(i,n)
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
;
residual(iter) = 0;
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
	);
	
* solve primal problem
embeddedcode reshop:
realAgent(a): min obj(a) x(a,i,n) q(a,i,n) s(a,i,n) multiplierFlow(a,i,n) defobj(a) defFlow(a,i,n)
priceAgent(i,n)$(sn(n)): vi defSupplydemand(i,n) p(i,n)
equ: Nash(realAgent(a),priceAgent(i,n)$(sn(n)))
endembeddedcode

	solve gasEnEqulibrium_RN using emp;

*   if bad things happen, exit the loop
*	if(gasEnEqulibrium_RN.solvestat > 1 or gasEnEqulibrium_RN.modelstat > 2,
*		break;
*	);

* 	unfix y
	y.lo(a,n)$(not nt(n,'t0')) = (1 - lambda)*prob(n);
	y.up(a,n)$(not nt(n,'t0')) = (1 - lambda)*prob(n) + lambda*prob(n)/(1-alpha);

*   fix x q s
	x.fx(a,i,n) = x.l(a,i,n);
	q.fx(a,i,n) = q.l(a,i,n);
	s.fx(a,i,n) = s.l(a,i,n);
	p.fx(i,n) = p.l(i,n);

*   turn on all risk agents (for zero detection)
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
riskAgent(a,n)$(controlN(a,n)): max yobj(a,n) y(a,child)$(succ(n,child))  multiplierRiskSet(a,n)
				defsupp(a,n) defriskSet(a,n)
equ: Nash(riskAgent(a,n)$(controlN(a,n)))
endembeddedcode

	solve gasEnEqulibrium_Dual using emp;

* unfix variables
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

currentResidual = meritTM;

*	if (currentResidual < minResidual,
*		minResidual = currentResidual;
*		x_best(a,i,n)$[ia(i,a) and sn(n)] = x.l(a,i,n);
*		q_best(a,i,n)$[ia(i,a) and sn(n)] = q.l(a,i,n);
*		s_best(a,i,n)$[ia(i,a) and sn(n)] = s.l(a,i,n);
*		y_best(a,n)$sn(n) = y.l(a,n);
*		p_best(i,n)$sn(n) = p.l(i,n);
*		defFlow_m_best(a,i,n)$[ia(i,a) and sn(n)] = defFlow.m(a,i,n);
*		defriskSet_m_best(a,n)$[not leafn(n)] = defriskSet.m(a,n);
*		defSupplydemand_m_best(i,n)$sn(n) = defSupplydemand.m(i,n);
*	);
*
*	if(currentResidual > lastResidual,
*      x.l(a,i,n)$[ia(i,a) and sn(n)] = 0.1*x_prev(a,i,n) + 0.9*x.l(a,i,n);
*      q.l(a,i,n)$[ia(i,a) and sn(n)] = 0.1*q_prev(a,i,n) + 0.9*q.l(a,i,n);
*      s.l(a,i,n)$[ia(i,a) and sn(n)] = 0.1*s_prev(a,i,n) + 0.9*s.l(a,i,n);
*      p.l(i,n)$sn(n) = 0.1*p_prev(i,n) + 0.9* p.l(i,n);
*      y.l(a,n)$sn(n) = 0.1*y_prev(a,n) + 0.9* y.l(a,n);
*      defFlow.m(a,i,n)$[ia(i,a) and sn(n)] = 0.1*defFlow_m(a,i,n) + 0.9*defFlow.m(a,i,n);
*      defriskSet.m(a,n)$[not leafn(n)] = 0.1*defriskSet_m(a,n) + 0.9*defriskSet.m(a,n);
*      defSupplydemand.m(i,n)$sn(n) = 0.1*defSupplydemand_m(i,n) + 0.9*defSupplydemand.m(i,n);
*	);

* check the residual 

* controlN(a,n) = yes;
* controlN(a,n)$(leafn(n)) = no;
 
* embeddedcode reshop:
* realAgent(a): min obj(a) x(a,i,n) q(a,i,n) s(a,i,n) defobj(a) defFlow(a,i,n)
* riskAgent(a,n)$(not leafn(n)): max yobj(a,n) y(a,child)$(succ(n,child)) defsupp(a,n) defriskSet(a,n)
* priceAgent(i,n)$(sn(n)): vi defSupplydemand(i,n) p(i,n)
* equ: Nash(realAgent(a),riskAgent(a,n)$(not leafn(n)),priceAgent(i,n)$(sn(n)))
* endembeddedcode

* 	gasEnEqulibrium.optfile = 2;
* 	solve gasEnEqulibrium using emp;

	if(currentResidual <= 1e-6,
	   break;
	);

*	if(iterationCount > 3 and currentResidual >= lastResidual,
*       x.l(a,i,n)$[ia(i,a) and sn(n)] = x_prev(a,i,n);
*       q.l(a,i,n)$[ia(i,a) and sn(n)] = q_prev(a,i,n);
*       s.l(a,i,n)$[ia(i,a) and sn(n)] = s_prev(a,i,n);
*       p.l(i,n)$sn(n) = p_prev(i,n);
*       y.l(a,n)$sn(n) = y_prev(a,n);
*       defFlow.m(a,i,n)$[ia(i,a) and sn(n)] = defFlow_m(a,i,n);
*       defriskSet.m(a,n)$[not leafn(n)] = defriskSet_m(a,n);
*       defSupplydemand.m(i,n)$sn(n) = defSupplydemand_m(i,n);
*	   residual(iter)$(ord(iter)=iterationCount+1) = currentResidual;
*	   break;
*	);
	

* *   if the residual is small enough, we break.


* 	if(gasEnEqulibrium.modelstat le 2,
*         x_prev(a,i,n)$[ia(i,a) and sn(n)] = x.l(a,i,n);
*         q_prev(a,i,n)$[ia(i,a) and sn(n)] = q.l(a,i,n);
*         s_prev(a,i,n)$[ia(i,a) and sn(n)] = s.l(a,i,n);
*         p_prev(i,n)$sn(n) = p.l(i,n);
*         y_prev(a,n)$sn(n) = y.l(a,n);
*         defFlow_m(a,i,n)$[ia(i,a) and sn(n)] = defFlow.m(a,i,n);
*         defriskSet_m(a,n)$[not leafn(n)] = defriskSet.m(a,n);
*         defSupplydemand_m(i,n)$sn(n) = defSupplydemand.m(i,n);
* 		break;
* 	);

*   if the residual increases too much, we restore the last solution and exit
*   the loop
*	if(iterationCount > 3 and currentResidual >= lastResidual,
*        x.l(a,i,n)$[ia(i,a) and sn(n)] = x_prev(a,i,n);
*        q.l(a,i,n)$[ia(i,a) and sn(n)] = q_prev(a,i,n);
*        s.l(a,i,n)$[ia(i,a) and sn(n)] = s_prev(a,i,n);
*        p.l(i,n)$sn(n) = p_prev(i,n);
*        y.l(a,n)$sn(n) = y_prev(a,n);
*        defFlow.m(a,i,n)$[ia(i,a) and sn(n)] = defFlow_m(a,i,n);
*        defriskSet.m(a,n)$[not leafn(n)] = defriskSet_m(a,n);
*        defSupplydemand.m(i,n)$sn(n) = defSupplydemand_m(i,n);
*		break;
*	);

	lastResidual = currentResidual;

	x_prev(a,i,n)$[ia(i,a) and sn(n)] = x.l(a,i,n);
	q_prev(a,i,n)$[ia(i,a) and sn(n)] = q.l(a,i,n);
	s_prev(a,i,n)$[ia(i,a) and sn(n)] = s.l(a,i,n);
	p_prev(i,n)$sn(n) = p.l(i,n);
	y_prev(a,n)$sn(n) = y.l(a,n);
	defFlow_m(a,i,n)$[ia(i,a) and sn(n)] = defFlow.m(a,i,n);
	defriskSet_m(a,n)$[not leafn(n)] = defriskSet.m(a,n);
	defSupplydemand_m(i,n)$sn(n) = defSupplydemand.m(i,n);

	residual(iter)$(ord(iter)=iterationCount+1) = currentResidual;
	iterationCount = iterationCount + 1;

	   proximalTerm = (iterationCount)/(10);
);

*   This should be eliminated later
*   What I found is that reshop flip the sign of muliplier
*   for defRiskSet
* defriskSet.m(a,n)$[not leafn(n)] = -defriskSet.m(a,n);
 
* 	make sure we unfix y as the algorithm can exit after primal step
* x.up(a,i,n) = xup;
* x.lo(a,i,n) = xlo;
* q.up(a,i,n) = Cap(a,i,n);
* q.lo(a,i,n) = 0;
* s.up(a,i,n) = +inf;
* s.lo(a,i,n) = 0;
* p.up(i,n) = +inf;
* p.lo(i,n) = 0;

* y.lo(a,n)$(not nt(n,'t0')) = (1 - lambda)*prob(n);
* y.up(a,n)$(not nt(n,'t0')) = (1 - lambda)*prob(n) + lambda*prob(n)/(1-alpha);

*	x.l(a,i,n)$[ia(i,a) and sn(n)] = x_best(a,i,n);
*	q.l(a,i,n)$[ia(i,a) and sn(n)] = q_best(a,i,n);
*	s.l(a,i,n)$[ia(i,a) and sn(n)] = s_best(a,i,n);
*	y.l(a,n)$sn(n) = y_best(a,n);
*	p.l(i,n)$sn(n) = p_best(i,n);
*	defFlow.m(a,i,n)$[ia(i,a) and sn(n)] = defFlow_m_best(a,i,n);
*	defriskSet.m(a,n)$[not leafn(n)] = -defriskSet_m_best(a,n);
*	defSupplydemand.m(i,n)$sn(n) = defSupplydemand_m_best(i,n);

* controlN(a,n) = yes;
* controlN(a,n)$(leafn(n)) = no;

* proximalTerm = 0;

*  multiplierFlow.fx(a,i,n) =  multiplierFlow.l(a,i,n);
*  multiplierRiskSet.fx(a,n) =  multiplierRiskSet.l(a,n);

* defFlow_original.m(a,i,n) = defFlow.m(a,i,n);
* defriskSet_original.m(a,n) = -defRiskSet.m(a,n);
* defSupplydemand_original.m(i,n) = defSupplydemand.m(i,n);

* solve the original model
* embeddedcode reshop:
* realAgent(a): min obj(a) x(a,i,n) q(a,i,n) s(a,i,n) multiplierFlow(a,i,n) defobj(a) defFlow(a,i,n)
* riskAgent(a,n)$(not leafn(n)): max yobj(a,n) y(a,child)$(succ(n,child)) multiplierRiskSet(a,i,n) defsupp(a,n) defriskSet(a,n)
* priceAgent(i,n)$(sn(n)): vi defSupplydemand(i,n) p(i,n)
* equ: Nash(realAgent(a),riskAgent(a,n)$(not leafn(n)),priceAgent(i,n)$(sn(n)))
* endembeddedcode

* embeddedcode reshop:
* realAgent(a): min obj(a) x(a,i,n) q(a,i,n) s(a,i,n) defobj_original(a) defFlow_original(a,i,n)
* riskAgent(a,n)$(not leafn(n)): max yobj(a,n) y(a,child)$(succ(n,child)) defsupp_original(a,n) defriskSet_original(a,n)
* priceAgent(i,n)$(sn(n)): vi defSupplydemand_original(i,n) p(i,n)
* equ: Nash(realAgent(a),riskAgent(a,n)$(not leafn(n)),priceAgent(i,n)$(sn(n)))
* endembeddedcode

* gasEnEqulibrium_original.optfile = 2;
* solve gasEnEqulibrium_original using emp;

display residual;

scalar final_residual ;

final_residual = meritTM;

display final_residual;