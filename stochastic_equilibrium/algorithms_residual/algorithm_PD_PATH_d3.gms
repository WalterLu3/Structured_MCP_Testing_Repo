* file: algorithm_PD_PATH.gms

* purpose: algorithm declaration


***** Algorithm : PD followed by PATH solve *****

* option file reshop.opt and path.opt to disable crash method.
* We do this because we want to use the accurate starting info.
* Other options are set based on Jiajie's file

alias(a,aaa);
alias(n,nnn);


scalar
	iZero
	tempade
;

alias(child,child2);

controlN(a,n) = no;

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
*put 'lemke_cycle_limit 100'/;
put 'factorization_method lusol'/;
put 'nms_large_reference_factor 1e12'/;
put 'restart_limit 0'/;
put 'output_warning 1'/;
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
;
iterationCount = 0;
currentResidual = 0;
lastResidual = +inf;

set
	iter /ii1*ii%iterationLimit%/;

set
	fixxx(a,n)
;

fixxx(a,n) = no;
set ti /ti1/;
set tii /ti2/;
set tiii /ti3/;

parameter
	pdTime(ti)
	solveTime(tii)
	failYes(tiii)
	xx(i,n)
	qq(i,n)
	ss(i,n)
	pp(i,n)
	yy(n)
;	




scalar
	pdT 
	temp
;
pdt = 0;
pdTime('ti1') = 0;
solveTime('ti2') = 0;
failYes('ti3') = -1;

parameter
*   take record of the last solution
	residual(iter)
	x_prev(a,i,n)
	q_prev(a,i,n)
	s_prev(a,i,n)
	p_prev(i,n)
	y_prev(a,n)
	defFlow_m(a,i,n)
	defriskSet_m(a,n)
	defSupplydemand_m(i,n)
;
residual(iter) = 0;
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
*		failYes('ti3') = 1;
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
	


	succContrN(a,n,child) = no;
	succContrN(a,n,child)$(succ(n,child) and controlN(a,n)) = yes;
 


*	tempade = costl('a1','n31') + costl('a1','n32') + costl('a1','n33') + costl('a1','n34') + costl('a1','n35');

*   solve dual problem
embeddedcode reshop:
riskAgent(a,n)$(controlN(a,n)): max yobj(a,n) y(a,child)$(succ(n,child)) 
				defsupp(a,n) defriskSet(a,n)
equ: Nash(riskAgent(a,n)$(controlN(a,n)))
endembeddedcode
*	xx(i,child)$succ('n14',child) = x.l('a2',i,child);
*	qq(i,child)$succ('n14',child) = q.l('a2',i,child);
*	ss(i,child)$succ('n14',child) = s.l('a2',i,child);
*	pp(i,child)$succ('n14',child) = p.l(i,child);


*	display xx, qq, ss, pp;
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

*  check the residual 

controlN(a,n) = yes;
controlN(a,n)$(leafn(n)) = no;
 

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

	residual(iter)$(ord(iter)=iterationCount+1) = currentResidual;
	iterationCount = iterationCount + 1;
);



* 	make sure we unfix y as the algorithm can exit after primal step
	x.up(a,i,n) = xup;
	x.lo(a,i,n) = xlo;
	q.up(a,i,n) = Cap(a,i,n);
	q.lo(a,i,n) = 0;
	s.up(a,i,n) = +inf;
	s.lo(a,i,n) = 0;
	p.up(i,n) = +inf;
	p.lo(i,n) = 0;

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
solveTime('ti2') =  gasEnEqulibrium.ResUsd;

set
	isChild(n);

isChild(child) = no;
isChild(child)$(succ('n9',child)) = yes;
display pdTime, solveTime, failYes;
display isChild;
*display tempade;