* file: model_dispatch_social_risk_agent.gms

* purpose: model declarations for social risk agents


*****************************************************
* Step 1. declare macro (cost)
*****************************************************

* not needed

*****************************************************
* Step 2. declare variables and equations
*****************************************************

Positive Variable
	y_social(n)    social risk probability
;

Variable
	yobj_social(n)         dual risk maximization for social risk agent
;

Equation
*   agent optimization problem with social risk probability
	defobj_social(a)            agent objective

*   risk optimization problem
	defsupp_social(n)         dual objective
    defriskSet_social(n)      dual risk constraint
;

* define extra control set to walk
* around zero objective for reshop
controlN(a,n) = yes;
controlN(a,n)$(leafn(n)) = no;

* --------------- agent problem --------------- 
* agent objective
defobj_social(a)..
	obj(a) =e= 
			sum(n$nt(n,'t1'),
				y_social(n)*(cost(a,n)
					+ sum(child$succ(n,child),
						y_social(child)*(cost(a,child)
							+ sum(grandchild$succ(child,grandchild),
								y_social(grandchild)*cost(a,grandchild)
							)
						)
					)
				)
			)
;

* --------------- risk problem --------------- 

* dual risk objective


defsupp_social(n)$[not leafn(n)]..
	yobj_social(n) =e=
	 sum(a, 
		sum(nt(n,'t0'), 
			sum(child$succ(n,child), y_social(child)* 
				(
					cost(a,child) + 
					sum(grandchild$succ(child, grandchild),
						y_social(grandchild)*(cost(a,grandchild)
							+ sum(ggrandchild$succ(grandchild, ggrandchild),
								y_social(ggrandchild)*cost(a,ggrandchild)
							)
						)
					)
				)
			) 
		)
	 	 
	 + sum(nt(n,'t1'), 
	 	sum(child$succ(n,child), y_social(child)* 
	 		(
	 			cost(a,child) + 
	 			sum(grandchild$succ(child, grandchild),
	 				y_social(grandchild)*cost(a,grandchild)
	 			)
	 		)
	 	) 
	 )
	 + sum(nt(n,'t2'),  sum(child$succ(n,child), y_social(child)*cost(a,child) ) )
	 )
;


* dual risk constraint: probability measure
defriskSet_social(n)$[not leafn(n)]..
	sum(child$succ(n,child), y_social(child) ) - 1 =e= 0
;




model gasEnEqulibrium_social /defobj_social, defFlow, defSupplydemand, defsupp_social, defriskSet_social/;
model gasEnEqulibrium_RN_social /defobj_social, defFlow, defSupplydemand/;
model gasEnEqulibrium_Dual_social /defsupp_social, defriskSet_social/;


*****************************************************
* Step 3. set variable bounds and initial data
*****************************************************

y_social.lo(n)$(not nt(n,'t0')) = (1 - lambda)*prob(n);
y_social.up(n)$(not nt(n,'t0')) = (1 - lambda)*prob(n) + lambda*prob(n)/(1-alpha);

y_social.l(n) = prob(n);



*****************************************************
* Step 4. some extra steps needed by different
*         market constraints.
*****************************************************

* skipped for social risk agent


* $ifthen %demandType% == 2
* * in the original implementation, the initial value
* * for the p_ref parameter for constraint type 2 is 
* * done by solving a risk neutrual problem

* gasEnEqulibrium_RN.holdFixed = 1;

* x.l(a,i,n)$[ia(i,a) and sn(n)] = 0.5*(x.lo(a,i,n) + x.up(a,i,n));
* q.l(a,i,n)$[ia(i,a) and sn(n)] = 0.5*(q.lo(a,i,n) + q.up(a,i,n));
* s.l(a,i,n)$[ia(i,a) and sn(n)] = 1;

* defFlow.m(a,i,n)$[ia(i,a) and sn(n)] = 1;
* p.l(i,n)$sn(n) = 1;

* loop(n$sn(n),
* 	y_social.fx(n) = prob(n);
* );

* * Primal PATH problem
* embeddedcode reshop:
* realAgent(a): min obj(a) x(a,i,n) q(a,i,n) s(a,i,n) defobj(a) defFlow(a,i,n)
* priceAgent(i,n)$(sn(n)): vi defSupplydemand(i,n) p(i,n)
* equ: Nash(realAgent(a),priceAgent(i,n)$(sn(n)))
* endembeddedcode

* solve gasEnEqulibrium_RN using emp;

* * release y variables (unfix them)
* y_social.lo(n)$(not nt(n,'t0')) = (1 - lambda)*prob(n);
* y_social.up(n)$(not nt(n,'t0')) = (1 - lambda)*prob(n) + lambda*prob(n)/(1-alpha);

* p_ref(i,n)$[sn(n)] = p.l(i,n);

* $endif