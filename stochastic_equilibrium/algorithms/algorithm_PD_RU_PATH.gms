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
	reportResidual(dum)
	reportPDTime(dum2)
	reportPATHTime(dum3)
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


* unfix variables
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



currentResidual = meritTM;

	if(iterationCount > 3 and currentResidual >= lastResidual,
       x.l(a,i,n)$[ia(i,a) and sn(n)] = x_prev(a,i,n);
       q.l(a,i,n)$[ia(i,a) and sn(n)] = q_prev(a,i,n);
       s.l(a,i,n)$[ia(i,a) and sn(n)] = s_prev(a,i,n);
       p.l(i,n)$sn(n) = p_prev(i,n);
       y.l(a,n)$sn(n) = y_prev(a,n);
       defFlow.m(a,i,n)$[ia(i,a) and sn(n)] = defFlow_m(a,i,n);
       defriskSet.m(a,n)$[not leafn(n)] = defriskSet_m(a,n);
       defSupplydemand.m(i,n)$sn(n) = defSupplydemand_m(i,n);
	   residual(iter)$(ord(iter)=iterationCount+1) = currentResidual;
	   break;
	);

	reportResidual('dummy') = currentResidual;

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
);
*   This should be eliminated later
*   What I found is that reshop flip the sign of muliplier
*   for defRiskSet
	reportPDTime('pd-time') = timeelapsed;
	defriskSet.m(a,n)$[not leafn(n)] = - defriskSet.m(a,n);
 
* 	make sure we unfix y as the algorithm can exit after primal step
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

*	x.l(a,i,n)$[ia(i,a) and sn(n)] = x_best(a,i,n);
*	q.l(a,i,n)$[ia(i,a) and sn(n)] = q_best(a,i,n);
*	s.l(a,i,n)$[ia(i,a) and sn(n)] = s_best(a,i,n);
*	y.l(a,n)$sn(n) = y_best(a,n);
*	p.l(i,n)$sn(n) = p_best(i,n);
*	defFlow.m(a,i,n)$[ia(i,a) and sn(n)] = defFlow_m_best(a,i,n);
*	defriskSet.m(a,n)$[not leafn(n)] = -defriskSet_m_best(a,n);
*	defSupplydemand.m(i,n)$sn(n) = defSupplydemand_m_best(i,n);

var.l(a,n) = -defriskSet.m(a,n);
defcost.m(a,n) = prod(nodePath(n,nn1), y.l(a,nn1));
defFlow_RU.m(a,i,n) = defFlow.m(a,i,n);

cvar_ineq.m(a,n) = sum(succ(parent,n), defcost.m(a,parent) * (y.l(a,n) - (1-lambda)*prob(n))); 
currentCost.l(a,n) = (costl(a,n))$(not n.first) + 
            sum(nn1$(nodePath(nn1,n) and not sameas(nn1,n)),
                  prod(nn2$(nodePath(nn1,nn2) and not nodePath(n,nn2)), y.l(a,nn2)) * 
                  (costl(a,nn1)));

adjustedCost.l(a,n) = sum(parent$succ(parent,n),max(0,currentCost.l(a,n) - var.l(a,parent)));
            

* main model
embeddedcode reshop:
producer(a): min EC(a) var(a,n) currentCost(a,n) adjustedCost(a,n) x(a,i,n) q(a,i,n) s(a,i,n) totalCost(a) cvar_ineq(a,n) defcost(a,n) defFlow_RU(a,i,n) 
priceAgent(i,n)$(sn(n)): vi defSupplydemand(i,n) p(i,n)
equ: Nash(producer(a),priceAgent(i,n)$(sn(n)))
endembeddedcode

gasEnEqulibrium_RU.optfile = 1;
solve gasEnEqulibrium_RU using emp;

abort$(gasEnEqulibrium_RU.modelstat > 2 or gasEnEqulibrium_RU.solveStat > 1 ) '##################### gasEnEqulibrium_RU fails to solve the model to optimality';

reportPATHTime('path-time') = timeelapsed - reportPDTime('pd-time');
display residual;

display reportResidual;

display reportPATHTime;
display reportPDTime;