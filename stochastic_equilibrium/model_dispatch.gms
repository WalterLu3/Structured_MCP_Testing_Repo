* file: model_dispatch.gms

* purpose: model declaration 


*****************************************************
* Step 1. declare macro (cost)
*****************************************************

* macro for stage cost
$ifthen %demandType% == 3
* type 3 constraint
$macro cost(a,n) \
		( sum(i,  \
			- (p_ref(i,n) + 1/(gamma_p*D(i,n))*(D(i,n) - sum(b, tau(b)*s(b,i,n))))*s(a,i,n) + 0.5*c1(a,i,n)*sqr(q(a,i,n)) + c2(a,i,n)*q(a,i,n) \
			+ 0.5*cs1(a,i,n)*sqr(s(a,i,n)) + cs2(a,i,n)*s(a,i,n) + cs3(a,i,n) \
			+ 0.5*cq1(a,i,n)*sqr(q(a,i,n)) + cq2(a,i,n)*q(a,i,n) + cq3(a,i,n) \
			+ 0.5*cx1(a,i,n)*sqr(x(a,i,n)) + cx2(a,i,n)*x(a,i,n) + cx3(a,i,n) \
		  ) \
		) 

$macro costl(a,n) \
		( sum(i,  \
			- (p_ref(i,n) + 1/(gamma_p*D(i,n))*(D(i,n) - sum(b, tau(b)*s.l(b,i,n))))*s.l(a,i,n) + 0.5*c1(a,i,n)*sqr(q.l(a,i,n)) + c2(a,i,n)*q.l(a,i,n) \
			+ 0.5*cs1(a,i,n)*sqr(s.l(a,i,n)) + cs2(a,i,n)*s.l(a,i,n) + cs3(a,i,n) \
			+ 0.5*cq1(a,i,n)*sqr(q.l(a,i,n)) + cq2(a,i,n)*q.l(a,i,n) + cq3(a,i,n) \
			+ 0.5*cx1(a,i,n)*sqr(x.l(a,i,n)) + cx2(a,i,n)*x.l(a,i,n) + cx3(a,i,n) \
		  ) \
		) 

$else
* type 1 and 2 constraints
$macro cost(a,n) \
		( sum(i,  \
			-tau(a)*p(i,n)*s(a,i,n) + 0.5*c1(a,i,n)*sqr(q(a,i,n)) + c2(a,i,n)*q(a,i,n) \
			+ 0.5*cs1(a,i,n)*sqr(s(a,i,n)) + cs2(a,i,n)*s(a,i,n) + cs3(a,i,n) \
			+ 0.5*cq1(a,i,n)*sqr(q(a,i,n)) + cq2(a,i,n)*q(a,i,n) + cq3(a,i,n) \
			+ 0.5*cx1(a,i,n)*sqr(x(a,i,n)) + cx2(a,i,n)*x(a,i,n) + cx3(a,i,n) \
		  ) \
		) 

* single stage cost with variable level values
$macro costl(a,n) \
		( sum(i,  \
			-tau(a)*p.l(i,n)*s.l(a,i,n) + 0.5*c1(a,i,n)*sqr(q.l(a,i,n)) + c2(a,i,n)*q.l(a,i,n) \
			+ 0.5*cs1(a,i,n)*sqr(s.l(a,i,n)) + cs2(a,i,n)*s.l(a,i,n) + cs3(a,i,n) \
			+ 0.5*cq1(a,i,n)*sqr(q.l(a,i,n)) + cq2(a,i,n)*q.l(a,i,n) + cq3(a,i,n) \
			+ 0.5*cx1(a,i,n)*sqr(x.l(a,i,n)) + cx2(a,i,n)*x.l(a,i,n) + cx3(a,i,n) \
		  ) \
		) 
$endif

* Macro related to zero objective detection
* stage 1 risk cost
$macro stage0Cost(a,n) \
	sum(nt(n,'t0'), \
	 	sum(child$succ(n,child), y.l(a,child)* \
	 		( \
	 			costl(a,child) + \
	 			sum(grandchild$succ(child, grandchild), \
	 				y.l(a,grandchild)*(costl(a,grandchild) \
	 					+ sum(ggrandchild$succ(grandchild, ggrandchild), \
	 						y.l(a,ggrandchild)*costl(a,ggrandchild) \
	 					) \
	 				) \
	 			) \
	 		) \
	 	) \
	 )

$macro stage1Cost(a,n) \
	sum(nt(n,'t1'), \
	 	sum(child$succ(n,child), y.l(a,child)* \
	 		( \
	 			costl(a,child) + \
	 			sum(grandchild$succ(child, grandchild), \
	 				y.l(a,grandchild)*costl(a,grandchild) \
	 			) \
	 		) \
	 	) \
	 )

$macro stage2Cost(a,n) \
	sum(nt(n,'t2'),  sum(child$succ(n,child), y.l(a,child)*costl(a,child) ) )


*****************************************************
* Step 2. declare variables and equations
*****************************************************

* define extra control set to walk
* around zero objective for reshop
set controlN(a,n)
;

controlN(a,n) = yes;
controlN(a,n)$(leafn(n)) = no;

Positive Variable
	q(a,i,n)  production
	x(a,i,n)  storage
	s(a,i,n)  sell
	p(i,n)    price
	y(a,n)    risk probability
;

Variable
	obj(a)            objective of supplier
	obj_dynamic(a,n)  dynamic version of supplier
	yobj(a,n)         dual risk maximization
	backwardObj       objective for backward LPs
	multiplierFlow(a,i,n)  multiplier for flow balance in backward backward experiemnts
	multiplierRiskSet(a,n) multiplier for risk set in backward backward experiemnts
;

Equation
*   agent optimization problem
	defobj(a)            agent objective
	defFlow(a,i,n)       agent storage constraint

*   dynamic version of agent problem
	defobj_dynamic(a,n)  agent objective in dynamic form

*   risk optimization problem
	defsupp(a,n)         dual objective
    defriskSet(a,n)      dual risk constraint

*   market VI
    defSupplydemand(i,n) price vi agent

*   LP problem during the backward LP solve
	defBackwardObj(a,n)
	defBackwardRiskSet(a,n)
;


* --------------- agent problem --------------- 
* agent objective
defobj(a)..
	obj(a) =e= 
	 	sum((i,n)$(not nt(n,'t0')), (proximalTerm/2) * (sqr(x(a,i,n) - x.l(a,i,n)) + sqr(q(a,i,n) - q.l(a,i,n)) + sqr(s(a,i,n) - s.l(a,i,n))))+
		sum((i,n)$[sn(n) and ia(i,a)], (proximalTerm/2) * (sqr(multiplierFlow(a,i,n)))) + 
			sum(n$nt(n,'t1'),
				y(a,n)*(cost(a,n)
					+ sum(child$succ(n,child),
						y(a,child)*(cost(a,child)
							+ sum(grandchild$succ(child,grandchild),
								y(a,grandchild)*cost(a,grandchild)
							)
						)
					)
				)
			)
;

* agent storage constraint

defFlow(a,i,n)$[sn(n) and ia(i,a)]..
	x(a,i,n) - sum(parentn(n, parent), x(a,i,parent)) + s(a,i,n) - q(a,i,n) 
	+ proximalTerm * (multiplierFlow(a,i,n) - multiplierFlow.l(a,i,n)) =e= 0;

* dynamic version of agent objective
defobj_dynamic(a,n)..
	obj_dynamic(a,n) =e= cost(a,n)$sn(n);

* --------------- risk problem --------------- 

* dual risk objective


defsupp(a,n)$[not leafn(n) and controlN(a,n)]..
	yobj(a,n) =e= 
	 sum(child$succ(n,child), (-proximalTerm/2) * sqr(y(a,child) - y.l(a,child))) +
	 ((-proximalTerm/2) * sqr(multiplierRiskSet(a,n)))+	
	 sum(nt(n,'t0'), 
	 	sum(child$succ(n,child), y(a,child)* 
	 		(
	 			cost(a,child) + 
	 			sum(grandchild$succ(child, grandchild),
	 				y(a,grandchild)*(cost(a,grandchild)
	 					+ sum(ggrandchild$succ(grandchild, ggrandchild),
	 						y(a,ggrandchild)*cost(a,ggrandchild)
	 					)
	 				)
	 			)
	 		)
	 	) 
	 )	 
	 + sum(nt(n,'t1'), 
	 	sum(child$succ(n,child), y(a,child)* 
	 		(
	 			cost(a,child) + 
	 			sum(grandchild$succ(child, grandchild),
	 				y(a,grandchild)*cost(a,grandchild)
	 			)
	 		)
	 	) 
	 )
	 + sum(nt(n,'t2'),  sum(child$succ(n,child), y(a,child)*cost(a,child) ) )
;

* dual risk constraint: probability measure
defriskSet(a,n)$[not leafn(n) and  controlN(a,n)]..
	sum(child$succ(n,child), y(a,child) ) - 1 
	+ proximalTerm * (multiplierRiskSet(a,n) - multiplierRiskSet.l(a,n)) =e= 0;

* --------------- vi agent ---------------

* demand satisfaction 
$ifthen %demandType% == 1 
defSupplydemand(i,n)$(sn(n))..
	sum(ia(i,a), tau(a)*s(a,i,n)) - D(i,n) + proximalTerm * (p(i,n) - p.l(i,n)) =g= 0;
$elseif %demandType% == 2
defSupplydemand(i,n)$(sn(n))..
	sum(ia(i,a), tau(a)*s(a,i,n)) - (D(i,n) - gamma_p*D(i,n)*(p(i,n) - p_ref(i,n))  ) + proximalTerm * (p(i,n) - p.l(i,n)) =g= 0;
$elseif %demandType% == 3
* for type 3 constraint
defSupplydemand(i,n)$(sn(n))..
	p(i,n) =e= 0;
$endif

* --------------- fixed probability agent --------
* Objective of the Backward LP problem
defBackwardObj(a_s,n_s)$[suba(a_s) and subn(n_s)]..
	backwardObj =e= 
	 sum(child$succ(n_s,child), y(a_s,child)*costOfChild(a_s,child))
;

* Constraint of the Backward LP problem
defBackwardRiskSet(a_s,n_s)$[suba(a_s) and subn(n_s)]..
	sum(child$succ(n_s,child), y(a_s,child) ) - 1 =e= 0
;



model gasEnEqulibrium /defobj, defFlow, defSupplydemand, defsupp, defriskSet/;
model gasEnEqulibrium_dynamic /defobj_dynamic, defFlow, defSupplydemand/;
model gasEnEqulibrium_RN /defobj, defFlow, defSupplydemand/;
model gasEnEqulibrium_Dual /defsupp, defriskSet/;
model gasEnEqulibrium_Dual_LP /defBackwardObj, defBackwardRiskSet/;

display nt;


*****************************************************
* Step 3. set variable bounds and initial data
*****************************************************

* variable bound
x.up(a,i,n)$[ia(i,a) and sn(n)] = xup;
x.lo(a,i,n)$[ia(i,a) and sn(n)] = xlo;
q.up(a,i,n)$[ia(i,a) and sn(n)] = Cap(a,i,n);

y.lo(a,n)$(not nt(n,'t0')) = (1 - lambda)*prob(n);
y.up(a,n)$(not nt(n,'t0')) = (1 - lambda)*prob(n) + lambda*prob(n)/(1-alpha);

*initial data
x.fx(a,i,'n0')$ia(i,a) = xStart(a,i);

y.l(a,n) = prob(n);

x.l(a,i,n)$[ia(i,a) and sn(n)] = 0.5*(x.lo(a,i,n) + x.up(a,i,n));
q.l(a,i,n)$[ia(i,a) and sn(n)] = 0.5*(q.lo(a,i,n) + q.up(a,i,n));
s.l(a,i,n)$[ia(i,a) and sn(n)] = 1;
p.l(i,n)$sn(n) = 1;

defFlow.m(a,i,n)$[ia(i,a) and sn(n)] = 0;
defRiskSet.m(a,n)$[not leafn(n)] = 0;

multiplierFlow.l(a,i,n) = 0;
multiplierRiskSet.l(a,n) = 0;


*****************************************************
* Step 4. some extra steps needed by different
*         market constraints.
*****************************************************

$ifthen %demandType% == 2
* in the original implementation, the initial value
* for the p_ref parameter for constraint type 2 is 
* done by solving a risk neutrual problem

gasEnEqulibrium_RN.holdFixed = 1;

x.l(a,i,n)$[ia(i,a) and sn(n)] = 0.5*(x.lo(a,i,n) + x.up(a,i,n));
q.l(a,i,n)$[ia(i,a) and sn(n)] = 0.5*(q.lo(a,i,n) + q.up(a,i,n));
s.l(a,i,n)$[ia(i,a) and sn(n)] = 1;

defFlow.m(a,i,n)$[ia(i,a) and sn(n)] = 1;
p.l(i,n)$sn(n) = 1;

loop(n$sn(n),
	y.fx(a,n) = prob(n);
);

* Primal PATH problem
embeddedcode reshop:
realAgent(a): min obj(a) x(a,i,n) q(a,i,n) s(a,i,n) defobj(a) defFlow(a,i,n)
priceAgent(i,n)$(sn(n)): vi defSupplydemand(i,n) p(i,n)
equ: Nash(realAgent(a),priceAgent(i,n)$(sn(n)))
endembeddedcode

solve gasEnEqulibrium_RN using emp;

* release y variables (unfix them)
y.lo(a,n)$(not nt(n,'t0')) = (1 - lambda)*prob(n);
y.up(a,n)$(not nt(n,'t0')) = (1 - lambda)*prob(n) + lambda*prob(n)/(1-alpha);

p_ref(i,n)$[sn(n)] = p.l(i,n);

$endif