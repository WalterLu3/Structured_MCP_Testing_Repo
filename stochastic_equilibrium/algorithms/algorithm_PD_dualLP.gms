* file: algorithm_PD_dualLP.gms

* purpose: algorithm declaration


***** Algorithm : PD, where D is a sequence of LPs *****
** Details: solve primal agent problem and dual risk poblems

* idea: 1. solve gasEnEqulibrium_yl for primal problem
*       2. backward solve for LP problem

*** Step 1: Write a loop for PD algorithm

scalar 
	iterationCount     count the number of iterations
;
iterationCount = 0;

option emp=reshop;
gasEnEqulibrium_RN.holdFixed = 1;

while(iterationCount < iterationLimit,

**** fix risk probability
	if(iterationCount eq 0,
		y.fx(a,n) = prob(n);
	else
		y.fx(a,n) = y.l(a,n);
	)

**** solve agents optimization equilibrium with fixed probability
embeddedcode reshop:
realAgent(a): min obj(a) x(a,i,n) q(a,i,n) s(a,i,n) 
                  defobj(a) defFlow(a,i,n)
priceAgent(i,n): vi defSupplydemand(i,n) p(i,n)
equ: Nash(realAgent(a),priceAgent(i,n))
endembeddedcode

	solve gasEnEqulibrium_RN using emp;

* 	unfix y
	y.lo(a,n) = (1 - lambda)*prob(n);
	y.up(a,n) = (1 - lambda)*prob(n) + lambda*prob(n)/(1-alpha);

*   fix x q s
	x.fx(a,i,n) = x.l(a,i,n);
	q.fx(a,i,n) = q.l(a,i,n);
	s.fx(a,i,n) = s.l(a,i,n);
	p.fx(i,n) = p.l(i,n);

**** if something failed, maybe we need to break the loop?
**** solve LPs in a backward manner

**** go through a loop from the last time stamp to the first
	loop(t$[ord(t) > 1],
		loop(revt(t,rt),
******** go through a loop for each node and each agent at the given time stamp
			loop(n$nt(n,rt),
				loop(a,
************ change dynamic set to choose the correct subproblem
					subn(n_s) = no;
					subchild(n_s) = no;
					suba(a_s) = no;
					subn(n) = yes;
					suba(a) = yes;
					subchild(n_s)$[succ(n,n_s)] = yes
************ set the children cost for caculation in LP problem
					if(sameAs(rt,'t2'),
						lpNormalizer = sum(child$succ(n,child), abs(costl(a,child)));
						costOfChild(a,subchild) = costl(a,subchild);
					elseif sameAs(rt,'t1'),
						lpNormalizer = sum(child$succ(n,child), 
											abs(costl(a,child) 
											+ sum(grandchild$succ(child,grandchild), 
											y.l(a,grandchild)*costl(a,grandchild) 
											)
											)
										);
						costOfChild(a,subchild) = costl(a,subchild) 
							+ sum(grandchild$succ(subchild,grandchild), 
								y.l(a,grandchild)*costl(a,grandchild))
					elseif sameAs(rt,'t0'),
						lpNormalizer = sum(child$succ(n,child), 
										   abs(costl(a,child) 
									       +sum(grandchild$succ(child,grandchild), 
										    y.l(a,grandchild)*(costl(a,grandchild) 
										   +sum(ggrandchild$succ(grandchild,ggrandchild), 
										    y.l(a,ggrandchild)*costl(a,ggrandchild)  
											   )  
										    ) 
									       )
								           ) 
							               );
						costOfChild(a,subchild) = costl(a,subchild) 
							+ sum(grandchild$succ(subchild,grandchild), 
								y.l(a,grandchild)*(costl(a,grandchild) 
									+ sum(ggrandchild$succ(grandchild,ggrandchild), 
										y.l(a,ggrandchild)*costl(a,ggrandchild))
									)  
								) 

					);
************ normalization of the cost
					costOfChild(a,subchild) = costOfChild(a,subchild)/(lpNormalizer + 1e-12);

					solve gasEnEqulibrium_Dual_LP using LP maximizing backwardObj;
				);
			);
		);
	);

**** unfix primal
	x.up(a,i,n) = xup;
	x.lo(a,i,n) = xlo;
	q.up(a,i,n) = Cap(a,i,n);
	q.lo(a,i,n) = 0;
	s.up(a,i,n) = +inf;
	s.lo(a,i,n) = 0;
	p.up(i,n) = +inf;
	p.lo(i,n) = 0;

**** increase the loop number
	iterationCount = iterationCount + 1;
);
