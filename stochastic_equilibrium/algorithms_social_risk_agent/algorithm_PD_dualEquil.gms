* file: algorithm_PD_dualEquil.gms

* purpose: algorithm declaration

***** Algorithm : PD with D be a equilibrium *****

scalar 
	iterationCount     count the number of iterations
;
iterationCount = 0;

option emp = reshop;
gasEnEqulibrium_RN.holdFixed = 1;
gasEnEqulibrium_Dual.holdFixed = 1;

* why do we need control set previously?

while(iterationCount < iterationLimit,
* 	fix y
* stopping condition using Fischer Burmeister

	if(iterationCount eq 0,
		y.fx(a,n) = prob(n);
	else
		y.fx(a,n) = y.l(a,n);
	)

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

embeddedcode reshop:
riskAgent(a,n)$(not leafn(n)): max yobj(a,n) y(a,child)$(succ(n,child)) 
				defsupp(a,n) defriskSet(a,n)
equ: Nash(riskAgent(a,n)$(not leafn(n)))
endembeddedcode

	solve gasEnEqulibrium_Dual using emp;

	x.up(a,i,n) = xup;
	x.lo(a,i,n) = xlo;
	q.up(a,i,n) = Cap(a,i,n);
	q.lo(a,i,n) = 0;
	s.up(a,i,n) = +inf;
	s.lo(a,i,n) = 0;
	p.up(i,n) = +inf;
	p.lo(i,n) = 0;

	iterationCount = iterationCount + 1;
);
