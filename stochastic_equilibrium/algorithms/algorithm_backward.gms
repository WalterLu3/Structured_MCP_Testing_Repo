* file: algorithm_PD.gms

* purpose: algorithm declaration


***** Algorithm : PD *****

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
	minResidual        
;
iterationCount = 0;
currentResidual = 0;
lastResidual = +inf;
minResidual = +inf;


set
	iter /ii1*ii%iterationLimit%/;

parameter
    x_iter17(a,i,n)
    q_iter17(a,i,n)
    s_iter17(a,i,n)
    y_iter17(a,n)
    p_iter17(i,n)

    x_iter19(a,i,n)
    q_iter19(a,i,n)
    s_iter19(a,i,n)
    y_iter19(a,n)
    p_iter19(i,n)
;

parameter
    defFlow_m_iter17(a,i,n)
    defriskSet_m_iter17(a,n)
    defSupplydemand_m_iter17(i,n)

    defFlow_m_iter19(a,i,n)
    defriskSet_m_iter19(a,n)
    defSupplydemand_m_iter19(i,n)
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

gasEnEqulibrium_RN_bw.holdFixed = 1;
gasEnEqulibrium_Dual_bw.holdFixed = 1;

proximal_bw = eps;

while(iterationCount < iterationLimit,
* 	fix y and solve primal agent problem

	if(iterationCount eq 0,
		y.fx(a,n)$sn(n) = prob(n);
	else
		y.fx(a,n)$sn(n) = y.l(a,n);
	);
	
* solve primal problem
embeddedcode reshop:
realAgent(a): min obj(a) x(a,i,n) q(a,i,n) s(a,i,n) multiplierFlow(a,i,n) defobj_bw(a) defFlow_bw(a,i,n)
priceAgent(i,n)$(sn(n)): vi defSupplydemand_bw(i,n) p(i,n)
equ: Nash(realAgent(a),priceAgent(i,n)$(sn(n)))
endembeddedcode

	solve gasEnEqulibrium_RN_bw using emp;

abort$(gasEnEqulibrium_RN_bw.modelstat > 2 or gasEnEqulibrium_RN_bw.solveStat > 1 ) '##################### gasEnEqulibrium_RN fails to solve the model to optimality';


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
	
*   solve dual problem
embeddedcode reshop:
riskAgent(a,n)$(controlN(a,n)): max yobj(a,n) y(a,child)$(succ(n,child)) multiplierRiskSet(a,n)
				defsupp_bw(a,n) defriskSet_bw(a,n)
equ: Nash(riskAgent(a,n)$(controlN(a,n)))
endembeddedcode

	solve gasEnEqulibrium_Dual_bw using emp;

abort$(gasEnEqulibrium_Dual_bw.modelstat > 2 or gasEnEqulibrium_Dual_bw.solveStat > 1 ) '##################### gasEnEqulibrium_Dual fails to solve the model to optimality';

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


	defFlow.m(a,i,n)$[ia(i,a) and sn(n)] = defFlow_bw.m(a,i,n);
	defriskSet.m(a,n)$[not leafn(n)] = defriskSet_bw.m(a,n);
	defSupplydemand.m(i,n)$sn(n) = defSupplydemand_bw.m(i,n);


if(iterationCount = 27,
    x_iter17(a,i,n)$[ia(i,a) and sn(n)] = x.l(a,i,n);
    q_iter17(a,i,n)$[ia(i,a) and sn(n)] = q.l(a,i,n);
    s_iter17(a,i,n)$[ia(i,a) and sn(n)] = s.l(a,i,n);
    y_iter17(a,n)$sn(n) = y.l(a,n);
    p_iter17(i,n)$sn(n) = p.l(i,n);
    defFlow_m_iter17(a,i,n)$[ia(i,a) and sn(n)]
        = defFlow_bw.m(a,i,n);

    defriskSet_m_iter17(a,n)$[not leafn(n)]
        = -defriskSet_bw.m(a,n);

    defSupplydemand_m_iter17(i,n)$sn(n)
        = defSupplydemand_bw.m(i,n);
);

if(iterationCount = 21,
    x_iter19(a,i,n)$[ia(i,a) and sn(n)] = x.l(a,i,n);
    q_iter19(a,i,n)$[ia(i,a) and sn(n)] = q.l(a,i,n);
    s_iter19(a,i,n)$[ia(i,a) and sn(n)] = s.l(a,i,n);
    y_iter19(a,n)$sn(n) = y.l(a,n);
    p_iter19(i,n)$sn(n) = p.l(i,n);
    defFlow_m_iter19(a,i,n)$[ia(i,a) and sn(n)]
        = defFlow_bw.m(a,i,n);

    defriskSet_m_iter19(a,n)$[not leafn(n)]
        = -defriskSet_bw.m(a,n);

    defSupplydemand_m_iter19(i,n)$sn(n)
        = defSupplydemand_bw.m(i,n);
);

currentResidual = meritTM;

residual(iter)$(ord(iter)=iterationCount+1) = currentResidual;
* check the residual 

	if(currentResidual <= 1e-6,
	   break;
	);


	lastResidual = currentResidual;

	x_prev(a,i,n)$[ia(i,a) and sn(n)] = x.l(a,i,n);
	q_prev(a,i,n)$[ia(i,a) and sn(n)] = q.l(a,i,n);
	s_prev(a,i,n)$[ia(i,a) and sn(n)] = s.l(a,i,n);
	p_prev(i,n)$sn(n) = p.l(i,n);
	y_prev(a,n)$sn(n) = y.l(a,n);
	defFlow_m(a,i,n)$[ia(i,a) and sn(n)] = defFlow_bw.m(a,i,n);
	defriskSet_m(a,n)$[not leafn(n)] = -defriskSet_bw.m(a,n);
	defSupplydemand_m(i,n)$sn(n) = defSupplydemand_bw.m(i,n);

	
	iterationCount = iterationCount + 1;

* proximal_bw = 1e-9;
if (iterationCount > 6,
	proximal_bw = (iterationCount)/100000;
);
* if (iterationCount > 6,
* 	proximal_bw = (iterationCount)/500000;
* );
);
*   This should be eliminated later
*   What I found is that reshop flip the sign of muliplier
*   for defRiskSet
	defFlow.m(a,i,n)$[ia(i,a) and sn(n)] = defFlow_bw.m(a,i,n);
	defriskSet.m(a,n)$[not leafn(n)] = -defriskSet_bw.m(a,n);
	defSupplydemand.m(i,n)$sn(n) = defSupplydemand_bw.m(i,n);
 
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



* solve the original model
embeddedcode reshop:
realAgent(a): min obj(a) x(a,i,n) q(a,i,n) s(a,i,n) defobj(a) defFlow(a,i,n)
riskAgent(a,n)$(not leafn(n)): max yobj(a,n) y(a,child)$(succ(n,child)) defsupp(a,n) defriskSet(a,n)
priceAgent(i,n)$(sn(n)): vi defSupplydemand(i,n) p(i,n)
equ: Nash(realAgent(a),riskAgent(a,n)$(not leafn(n)),priceAgent(i,n)$(sn(n)))
endembeddedcode

gasEnEqulibrium.optfile = 2;
solve gasEnEqulibrium using emp;

* defriskSet.m(a,n)$[not leafn(n)] = - defriskSet.m(a,n);

* currentResidual = meritTM;
display residual;
* display currentResidual;

scalar
    diff_x
    diff_q
    diff_s
    diff_y
    diff_p
    diff_all
;

diff_x = smax((a,i,n)$[ia(i,a) and sn(n)],
             abs(x_iter17(a,i,n) - x_iter19(a,i,n)));

diff_q = smax((a,i,n)$[ia(i,a) and sn(n)],
             abs(q_iter17(a,i,n) - q_iter19(a,i,n)));

diff_s = smax((a,i,n)$[ia(i,a) and sn(n)],
             abs(s_iter17(a,i,n) - s_iter19(a,i,n)));

diff_y = smax((a,n)$sn(n),
             abs(y_iter17(a,n) - y_iter19(a,n)));

diff_p = smax((i,n)$sn(n),
             abs(p_iter17(i,n) - p_iter19(i,n)));

diff_all = max(diff_x, diff_q, diff_s, diff_y, diff_p);

display diff_x, diff_q, diff_s, diff_y, diff_p, diff_all;

minResidual = smin(iter$(ord(iter) <= iterationCount + 1),
                   residual(iter));

display minResidual;