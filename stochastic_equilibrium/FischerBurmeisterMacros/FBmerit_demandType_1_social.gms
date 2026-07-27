$macro defxdevF(a,i,n)	\
		(\
			sum(nt(n,'t1'), \
				y_social.l(n)*(cx1(a,i,n)*x.l(a,i,n) + cx2(a,i,n)) 	\
			)	\
			+ 	\
			sum(nt(n,'t2'),	\
				sum(parent$succ(parent,n),	\
					y_social.l(parent)*y_social.l(n)*(cx1(a,i,n)*x.l(a,i,n) + cx2(a,i,n))	\
				)	\
			)	\
			+ 	\
			sum(nt(n,'t3'),	\
				sum(parent$succ(parent,n),	\
					sum(child$succ(child,parent),	\
						y_social.l(child)*y_social.l(parent)*y_social.l(n)*(cx1(a,i,n)*x.l(a,i,n) + cx2(a,i,n)) 	\
					)	\
				)	\
			)	\
			- defFlow.m(a,i,n) + sum(child$succ(n,child), defFlow.m(a,i,child))	\
		)\


$macro defqdevF(a,i,n)	\
		(\
			sum(nt(n,'t1'), \
				y_social.l(n)*(cq1(a,i,n)*q.l(a,i,n) + cq2(a,i,n) + c1(a,i,n)*q.l(a,i,n) + c2(a,i,n))  \
			) \
			+  \
			sum(nt(n,'t2'), \
				sum(parent$succ(parent,n), \
					y_social.l(parent)*y_social.l(n)*(cq1(a,i,n)*q.l(a,i,n) + cq2(a,i,n) + c1(a,i,n)*q.l(a,i,n) + c2(a,i,n)) \
				) \
			) \
			+ \
			sum(nt(n,'t3'), \
				sum(parent$succ(parent,n), \
					sum(child$succ(child,parent), \
						y_social.l(child)*y_social.l(parent)*y_social.l(n)*(cq1(a,i,n)*q.l(a,i,n) + cq2(a,i,n) + c1(a,i,n)*q.l(a,i,n) + c2(a,i,n)) \ 
					) \
				) \
			) \
			+ defFlow.m(a,i,n) \
		)\


$macro defsdevF(a,i,n) \
		(\
			sum(nt(n,'t1'), \
				y_social.l(n)*(cs1(a,i,n)*s.l(a,i,n) + cs2(a,i,n) - tau(a)*p.l(i,n))  \
			) \
			+  \
			sum(nt(n,'t2'), \
				sum(parent$succ(parent,n), \
					y_social.l(parent)*y_social.l(n)*(cs1(a,i,n)*s.l(a,i,n) + cs2(a,i,n) - tau(a)*p.l(i,n)) \
				) \
			) \
			+  \
			sum(nt(n,'t3'), \
				sum(parent$succ(parent,n), \
					sum(child$succ(child,parent), \
						y_social.l(child)*y_social.l(parent)*y_social.l(n)*(cs1(a,i,n)*s.l(a,i,n) + cs2(a,i,n) - tau(a)*p.l(i,n))  \
					) \
				) \
			) \
			- defFlow.m(a,i,n) \
		)\

$macro defFlowF(a,i,n) (x.l(a,i,n) - sum(parentn(n, parent), x.l(a,i,parent)) + s.l(a,i,n) - q.l(a,i,n))

$macro defSupplydemandF(i,n) (sum(ia(i,a), tau(a)*s.l(a,i,n)) - D(i,n) )

$macro defydevF(n) \
		(\
			- \
			sum(a, \
			sum(nt(n,'t1'), \ 
				costl(a,n) + \
				sum(child$succ(n,child), \
					y_social.l(child)* \
					(costl(a,child) + \
						sum(grandchild$succ(child,grandchild), \
							y_social.l(grandchild)*costl(a, grandchild) \
						)	\
					)\
				)\
			) \
			+ \
			sum(nt(n,'t2'), \
				costl(a,n) + \
				sum(child$succ(n,child), \
					y_social.l(child)*costl(a,child) \
				)\
			)\ 	 
			+ \
			sum(nt(n, 't3'), \
				costl(a,n) \
			) \
			) \
			+ sum(parent$succ(parent,n), defriskSet_social.m(parent) ) \
		)\

$macro defriskSetF(n) ( sum(child$succ(n,child), y_social.l(child) ) - 1 ) 


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

$macro meritFunyM(n) \
		ncpF(y_social.l(n) - y_social.lo(n), \
		ncpF(y_social.up(n) - y_social.l(n),  - defydevF(n)  ) )	\

$macro meritFunRiskM(n) \
		(0 - defriskSetF(n)) \

$macro meritTM	\
		sqrt(\
			sum(ain(a,i,n),	\
				sqr(meritFunXM(a,i,n)) + \			
				sqr(meritFunSM(a,i,n)) + \
				sqr(meritFunQM(a,i,n)) + \
				sqr(meritFunflowM(a,i,n)) \
		  	)	\
			+ sum(in(i,n), sqr(meritFunSupplyM(i,n)) )\
			+ \
				sum(n$[not leafn(n)], \
					sqr( meritFunRiskM(n) )  \
				)  \
			\
			+ \
				sum(n$sn(n), \
					sqr( meritFunyM(n) ) \
				) \
			\
		)	\