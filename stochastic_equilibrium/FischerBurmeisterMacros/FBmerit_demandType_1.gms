$macro defxdevF(a,i,n)	\
		(\
			sum(nt(n,'t1'), \
				y.l(a,n)*(cx1(a,i,n)*x.l(a,i,n) + cx2(a,i,n)) 	\
			)	\
			+ 	\
			sum(nt(n,'t2'),	\
				sum(parent$succ(parent,n),	\
					y.l(a,parent)*y.l(a,n)*(cx1(a,i,n)*x.l(a,i,n) + cx2(a,i,n))	\
				)	\
			)	\
			+ 	\
			sum(nt(n,'t3'),	\
				sum(parent$succ(parent,n),	\
					sum(child$succ(child,parent),	\
						y.l(a,child)*y.l(a,parent)*y.l(a,n)*(cx1(a,i,n)*x.l(a,i,n) + cx2(a,i,n)) 	\
					)	\
				)	\
			)	\
			- defFlow.m(a,i,n) + sum(child$succ(n,child), defFlow.m(a,i,child))	\
		)\


$macro defqdevF(a,i,n)	\
		(\
			sum(nt(n,'t1'), \
				y.l(a,n)*(cq1(a,i,n)*q.l(a,i,n) + cq2(a,i,n) + c1(a,i,n)*q.l(a,i,n) + c2(a,i,n))  \
			) \
			+  \
			sum(nt(n,'t2'), \
				sum(parent$succ(parent,n), \
					y.l(a,parent)*y.l(a,n)*(cq1(a,i,n)*q.l(a,i,n) + cq2(a,i,n) + c1(a,i,n)*q.l(a,i,n) + c2(a,i,n)) \
				) \
			) \
			+ \
			sum(nt(n,'t3'), \
				sum(parent$succ(parent,n), \
					sum(child$succ(child,parent), \
						y.l(a,child)*y.l(a,parent)*y.l(a,n)*(cq1(a,i,n)*q.l(a,i,n) + cq2(a,i,n) + c1(a,i,n)*q.l(a,i,n) + c2(a,i,n)) \ 
					) \
				) \
			) \
			+ defFlow.m(a,i,n) \
		)\


$macro defsdevF(a,i,n) \
		(\
			sum(nt(n,'t1'), \
				y.l(a,n)*(cs1(a,i,n)*s.l(a,i,n) + cs2(a,i,n) - tau(a)*p.l(i,n))  \
			) \
			+  \
			sum(nt(n,'t2'), \
				sum(parent$succ(parent,n), \
					y.l(a,parent)*y.l(a,n)*(cs1(a,i,n)*s.l(a,i,n) + cs2(a,i,n) - tau(a)*p.l(i,n)) \
				) \
			) \
			+  \
			sum(nt(n,'t3'), \
				sum(parent$succ(parent,n), \
					sum(child$succ(child,parent), \
						y.l(a,child)*y.l(a,parent)*y.l(a,n)*(cs1(a,i,n)*s.l(a,i,n) + cs2(a,i,n) - tau(a)*p.l(i,n))  \
					) \
				) \
			) \
			- defFlow.m(a,i,n) \
		)\

$macro defFlowF(a,i,n) (x.l(a,i,n) - sum(parentn(n, parent), x.l(a,i,parent)) + s.l(a,i,n) - q.l(a,i,n))

$macro defSupplydemandF(i,n) (sum(ia(i,a), tau(a)*s.l(a,i,n)) - D(i,n) )

$macro defydevF(a,n) \
		(\
			- \
			sum(nt(n,'t1'), \ 
				costl(a,n) + \
				sum(child$succ(n,child), \
					y.l(a,child)* \
					(costl(a,child) + \
						sum(grandchild$succ(child,grandchild), \
							y.l(a, grandchild)*costl(a, grandchild) \
						)	\
					)\
				)\
			) \
			- \
			sum(nt(n,'t2'), \
				costl(a,n) + \
				sum(child$succ(n,child), \
					y.l(a,child)*costl(a,child) \
				)\
			)\ 	 
			- \
			sum(nt(n, 't3'), \
				costl(a,n) \
			) \
			+ sum(parent$succ(parent,n), defriskSet.m(a,parent) ) \
		)\

$macro defriskSetF(a,n) ( sum(child$succ(n,child), y.l(a,child) ) - 1 ) 


$macro meritFunXM(a,i,n)	\
		ncpF(x.l(a,i,n) - xlo, \
		ncpF(xup - x.l(a,i,n),  - defxdevF(a,i,n)  ) )	\


$macro meritFunSM(a,i,n) \
		ncpF( s.l(a,i,n) - 0, defsdevF(a,i,n) )	\

$macro meritFunQM(a,i,n)	\
		ncpF(q.l(a,i,n) - 0, \
		ncpF(Cap(a,i,n) - q.l(a,i,n),  - defqdevF(a,i,n)    ) )	\

$macro meritFunflowM(a,i,n)	\
		(0 - defFlowF(a,i,n) )	\

$macro meritFunSupplyM(i,n)	\
		ncpF(p.l(i,n) - 0, defSupplydemandF(i,n) )	\

$macro meritFunyM(a,n) \
		ncpF(y.l(a,n) - y.lo(a,n), \
		ncpF(y.up(a,n) - y.l(a,n),  - defydevF(a,n)  ) )	\

$macro meritFunRiskM(a,n) \
		(0 - defriskSetF(a,n)) \

$macro meritTM	\
		sqrt(\
			sum(ain(a,i,n),	\
				sqr(meritFunXM(a,i,n)) + \			
				sqr(meritFunSM(a,i,n)) + \
				sqr(meritFunQM(a,i,n)) + \
				sqr(meritFunflowM(a,i,n)) \
		  	)	\
			+ sum(in(i,n), sqr(meritFunSupplyM(i,n)) )\
			+ sum(a, \ 
				sum(n$[not leafn(n)], \
					sqr( meritFunRiskM(a,n) )  \
				)  \
			) \
			+ sum(a, \
				sum(n$sn(n), \
					sqr( meritFunyM(a,n) ) \
				) \
			) \
		)	\