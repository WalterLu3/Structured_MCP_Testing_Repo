
* ==> opt_cont.gms

$title An Optimal Control ELQP 
$offsymxref offsymlist offuellist offuelxref
$inlinecom /* */

/* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  This file contains an Extended Linear-Quadratic Program (ELQP)
formulated as an MCP.  See

  R.T. Rockafellar, "Linear-Quadratic Programming and Optimal
Control", SIAM J. Control and Optimization 25 3, 1987, p. 781-814.

 In general, an ELQP consists of primal and dual problems of the
following form: 

   (P):	min  pu + 1/2 uPu + rho_{V,Q}(q - Ru)
	s.t.	u in U

   (D): max  qv - 1/2 vQv - rho_{U,P}(R^v - p)
	s.t.	v in V

  where P and Q are positive semidefinite matrices,
  p and q are vectors, u and v are variables in the
  feasible sets U \subset R^n, V \subset R^m,
  and rho_{X,D} is a piecewise linear-quadratic penalty
  function depending on the feasible set X and matrix D.

  The optimality conditions for the ELQP are equivalent to
  VI(T,U \cross V), where T(u,v) follows.  It is this VI which
  we formulate as a MCP.

   T(u,v) :=	(Pu - R'v + p)
		(Ru + Qv  - q)



  The ELQP in question arises from the discretization of the
  following continuous (primal) optimal control problem:

		  t_R
		integral [p(t)*u(t) + 1/2 u(t)*P(t)*u(t) - c(t)*x(t)] dt   +
		  t_L

		p^L*u^L + 1/2 u^L*P_L*u^L  - c^R*x(t_L)     +
	min	
		  t_R
		integral rho(q(t) - C(t)*x(t) - D(t)*u(t)) dt   +
		  t_L

		rho(q^R - C_R*x(t_R))


	s.t.	(dx/dt)(t) = A(t)*x(t) + B(t)*u(t) + b(t),
		x(t_L) = B_L*u^L + b^L

  where u^L are some initial control variables,
  u(t) the controls at time t, x(t) the state at time t.
  The dual, not given here, has state variables y(t),
  controls v(t), and a terminal control variable v_T.

  For any N >= 1, the interval [L, R] is divided into N pieces by a
uniform mesh of N+1 points, including endpoints L and R. For the
primal problem, our discretization includes N+1 state vectors:
x^1=x(L), .., x^N, xR = x(R).  The control vectors at the first N mesh
points are u^1, .., u^N.  No control vector is needed for the right
endpoint; however, there is the control vector u^L==uI,
the initial control which determines state x(t_L).

  It is not necessary to specify the dual problem; it is implicit in
the primal.  FYI, our dual state variables are yL=y(L), y^1, .., y^N =
y(R), while there is no dual control for the left endpoint; instead,
v^1, .., y^N are the dual control variables at the last N mesh points.
There is an additional control vector yT to enforce a terminal
condition on the dual states.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% */

  
sets
mesh		/ 1 * 1000 /,	/* points 1 .. N in primal & dual mesh */
controls	/ 1 * 8 /,	/* controls */
icontrols	/ 1 * 8 /,	/* initial controls */
states		/ 1 * 8 /,	/* states */
/* ds				   duals to states */
duals		/ 1 * 8 /,	/* dual controls, or constraint multipliers */
tduals		/ 1 * 8 /;	/* terminal dual controls */
option seed = 87;

alias	(ds, states),
	(controls, controls2),
	(icontrols, icontrols2),
	(duals, duals2),
	(tduals, tduals2);

scalar
pcount,			/* count of primal variables */
dcount,			/* count of dual variables */
timespan,		/* t_R - t_L */
N;			/* number of grid (mesh) points */

timespan = 1;
N = card(mesh);
pcount = N * (card(controls) + card(states))
	    + card(icontrols) +card(states);
dcount = N * (card(duals) + card(ds))
	    + card(tduals) +card(ds);
/* problem size for final MCP is
   N * (#controls + #duals + 2 * #states))
   + #icontrols + #tduals + 2 * #states */

parameters
u_lo(controls),
u_up(controls),
uI_lo(icontrols),
uI_up(icontrols),

v_lo(duals),
v_up(duals),
vT_lo(tduals),
vT_up(tduals),

P(controls,controls2),
pp(controls),
PI(icontrols, icontrols2),
ppI(icontrols),

Q(duals,duals2),
qq(duals),
QT(tduals, tduals2),
qqT(tduals),

A(ds, states),
B(ds, controls),
bb(ds),
BI(ds, icontrols),
bbI(ds),

C(duals, states),
cc(states),
CT(tduals, states),
ccT(states),

D(duals, controls);

/* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   All the parameters have been declared; we must now define
   them.
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% */


u_up(controls) = uniform(-5, 5);
u_lo(controls) = u_up(controls) - uniform(0, 4.5);
uI_up(icontrols) = uniform(-5, 5);
uI_lo(icontrols) = uI_up(icontrols) - uniform(0, 4);

v_up(duals) = uniform(-5, 5);
v_lo(duals) = v_up(duals) - uniform(0, 4);
vT_up(tduals) = uniform(-5, 5);
vT_lo(tduals) = vT_up(tduals) - uniform(0, 4);

P(controls,controls) = uniform(1, 3);
pp(controls) = uniform(-2, 2);
PI(icontrols, icontrols) = uniform(1, 3);
ppI(icontrols) = uniform(-2, 2);

Q(duals,duals) = uniform(1, 3);
qq(duals) = uniform(-2, 2);
QT(tduals, tduals) = uniform(1, 3);
qqT(tduals) = uniform(-2, 2);

A(ds, states) = uniform(-0.9, 0.9);
B(ds, controls) = uniform(-0.2, 0.2);
bb(ds) = uniform(-0.5, 0.5);
BI(ds, icontrols) = uniform(-0.2, 0.2);
bbI(ds) = uniform(-0.5, 0.5);

C(duals, states) = uniform(-0.2, 0.2);
cc(states) = uniform(-0.5, 0.5);
CT(tduals, states) = uniform(-0.2, 0.2);
ccT(states) = uniform(-0.5, 0.5);

D(duals, controls) = uniform(-10, 10);

/* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   The parameters are defined.  Now
   declare the variables and equations,
   and define the functions and the
   box constraints.
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% */


variables
uI(icontrols),		/* initial control variables */
u(mesh, controls),	/* control variables for [L,R) */
x(mesh, states),	/* state variables for [L,R) */
xR(states),		/* state variables at t=R */
v(mesh, duals),		/* dual control vars, (L,R] */
vT(tduals),		/* terminal dual control vars */
yL(ds),			/* dual state vars at t=L */
y(mesh, ds);		/* dual state vars, (L,R] */

uI.lo(icontrols) = uI_lo(icontrols);
uI.up(icontrols) = uI_up(icontrols);
u.lo(mesh,controls) = u_lo(controls);
u.up(mesh,controls) = u_up(controls);
v.lo(mesh,duals) = v_lo(duals);
v.up(mesh,duals) = v_up(duals);
vT.lo(tduals) = vT_lo(tduals);
vT.up(tduals) = vT_up(tduals);

/* 
uI.lo(icontrols) = (uI_lo(icontrols) + uI_up(icontrols)) / 2;
u.l(mesh,controls) = (u_lo(controls) + u_up(controls)) / 2;
v.lo(mesh,duals) = (v_lo(duals) + v_up(duals)) / 2;
vT.lo(tduals) = (vT_lo(tduals) + vT_up(tduals)) / 2;
*/

equations
deluI(icontrols),
delu(mesh, controls),
delx(mesh, states),
delxR(states),
delv(mesh, duals),
delvT(tduals),
delyL(ds),
dely(mesh, ds);

deluI(icontrols) ..
	sum(icontrols2, PI(icontrols, icontrols2) * uI(icontrols2))
	+ ppI(icontrols)
	- sum(ds, yL(ds) * BI(ds, icontrols))
	=g= 0;
delu(mesh, controls) ..
	( sum(controls2, P(controls,controls2) * u(mesh,controls2))
	+ pp(controls)
	- sum(duals, v(mesh,duals) * D(duals,controls))
	- sum(ds, y(mesh,ds) * B(ds, controls)) * timespan
	) / N
	=g= 0;
delx(mesh, states) ..
	y(mesh-1,states) + (yL(states)) $(ord(mesh) eq 1)
	=e=
	y(mesh,states)
	+ ( cc(states)
	  + sum(ds, y(mesh,ds) * A(ds,states)) * timespan
	  + sum(duals, v(mesh,duals) * C(duals, states))
	  ) / N;
delxR(states) ..
	- ccT(states)
	- sum(tduals, vT(tduals) * CT(tduals, states))
	+ sum(mesh$(ord(mesh) eq N), y(mesh,states))
	=e= 0;
delv(mesh,duals) ..
	( sum(controls, D(duals,controls) * u(mesh,controls))
	+ sum(states, C(duals,states) * x(mesh,states))
	+ sum(duals2, Q(duals, duals2) * v(mesh,duals2))
	- qq(duals)
	) / N
	=g= 0;
delvT(tduals) ..
	sum(states, CT(tduals,states) * xR(states))
	+ sum(tduals2, QT(tduals,tduals2) * vT(tduals2))
	- qqT(tduals)
	=g= 0;
delyL(ds) ..
	sum(icontrols, BI(ds, icontrols) * uI(icontrols))
	+ bbI(ds)
	=e=
	x("1",ds);
dely(mesh,ds) ..
	x(mesh,ds)
	+ ( sum(controls, B(ds, controls) * u(mesh,controls))
	   + sum(states, A(ds,states) * x(mesh,states))
	   + bb(ds)
	  ) * timespan / N
	=e=
	x(mesh+1,ds)
	+ (xR(ds)) $(ord(mesh) eq N);

model elqp	/ deluI.uI, delu.u, delx.x, delxR.xR, delv.v,
delvT.vT, delyL.yL, dely.y /;

option limrow = 0;
option limcol = 0;
option solprint = off;
option iterlim = 20000;
option reslim = 14400;		/* 4 hours */

file cp /out.pth/;
file qpf /out.mns/;
file cp_obj /obj.pth/;
file qpf_obj /obj.mns/;


scalars
penalty,
object;

uI.l(icontrols) = 0;
u.l(mesh,controls) = 0;
v.l(mesh,duals) = 0;
vT.l(tduals) = 0;
x.l(mesh, states) = 0;
xR.l(states) = 0;
v.l(mesh, duals) = 0;
vT.l(tduals) = 0;

file polystructure / 'poly.txt' /;
put polystructure;
loop ( (mesh,ds),
   put dely(mesh,ds)/;
);
*loop ((mesh, controls),
*   put delu(mesh, controls)/;
* );
putclose polystructure;


solve elqp using mcp;
$exit
penalty = sum (mesh,
	sum(duals, v.l(mesh,duals) * (qq(duals)
	   - sum(controls, D(duals,controls) * u.l(mesh,controls))
	   - sum(states, C(duals,states) * x.l(mesh,states))
	   - 0.5 * sum(duals2, Q(duals,duals2) * v.l(mesh,duals2))
	) ) ) / N
	+ sum(tduals, vT.l(tduals) * (qqT(tduals)
	   - sum(states, CT(tduals,states) * xR.l(states))
	   - 0.5 * sum(tduals2, QT(tduals,tduals2) * vT.l(tduals2))
	) );
	

object = sum(mesh,
sum(controls,u.l(mesh,controls) * (pp(controls) +
	 0.5*sum(controls2,P(controls,controls2)*u.l(mesh,controls2)) ) )
- sum(states, x.l(mesh,states) * cc(states))
) / N
+ sum(icontrols,uI.l(icontrols) * (ppI(icontrols) +
     0.5*sum(icontrols2,PI(icontrols,icontrols2)*uI.l(icontrols2))) )
- sum(states, xR.l(states) * ccT(states))
+ penalty;

put cp_obj;
put "ELQP   primals:" pcount:5:0 "    duals:" dcount:5:0 /;
put "objective function value: " object:15:8 /;

put cp;
$include "put.pth"

/* start stuff for QP */
putclose cp;
putclose cp_obj;

/* QP formulation described in

	R.T. Rockafellar and R.J.-B. Wets,
	"A Lagrangian Finite Generation Technique for Solving
	Linear-Quadratic Problems in Stochastic Programming",
	Math. Prog. Study 28 (1986) 63-93
*/


positive variables
vTdup(tduals),
vTdlo(tduals),
vdup(mesh,duals),
vdlo(mesh,duals);

variables
z,		/* objective value */
vv(mesh,duals),	/* u'' of RTR paper */
vvT(tduals);	/* u'' of RTR paper */

equations
obj,
rfv(mesh,duals),
rfvT(tduals),
rfyL(ds),
rfy(mesh,ds);

obj ..	z =e=
sum(icontrols, uI(icontrols) * (ppI(icontrols)
+ 0.5 * sum(icontrols2, PI(icontrols, icontrols2) * uI(icontrols2)) )
)
+ sum(mesh,
   sum(controls, u(mesh,controls) * (pp(controls)
   + 0.5 * sum(controls2, P(controls,controls2) * u(mesh,controls2)) ) )
 - sum(states, x(mesh,states) * cc(states) )
) / N

- sum(states, xR(states)*ccT(states))

+ sum(mesh,
   sum(duals, v_up(duals) * vdup(mesh,duals)
             -v_lo(duals) * vdlo(mesh,duals))
)
+ sum(tduals, vT_up(tduals) * vTdup(tduals)
	     -vT_lo(tduals) * vTdlo(tduals))

+ 0.5 * sum(mesh,
   sum(duals, vv(mesh,duals) *
	sum(duals2, Q(duals,duals2)*vv(mesh,duals2)))
 ) / N
+ 0.5 * sum(tduals, vvT(tduals) *
	    sum(tduals2, QT(tduals,tduals2)*vvT(tduals2)));



rfv(mesh,duals) ..
	( sum(controls, D(duals,controls) * u(mesh,controls))
	+ sum(states, C(duals,states) * x(mesh,states))
	+ sum(duals2, Q(duals, duals2) * vv(mesh,duals2))
	- qq(duals)
	) / N
	+ vdup(mesh,duals) - vdlo(mesh,duals)
	=e= 0;
rfvT(tduals) ..
	sum(states, CT(tduals,states) * xR(states))
	+ sum(tduals2, QT(tduals,tduals2) * vvT(tduals2))
	- qqT(tduals)
	+ vTdup(tduals) - vTdlo(tduals)
	=e= 0;
rfyL(ds) ..
	sum(icontrols, BI(ds, icontrols) * uI(icontrols))
	+ bbI(ds)
	=e=
	x("1",ds);
rfy(mesh,ds) ..
	x(mesh,ds)
	+ ( sum(controls, B(ds, controls) * u(mesh,controls))
	   + sum(states, A(ds,states) * x(mesh,states))
	   + bb(ds)
	  ) * timespan / N
	=e=
	x(mesh+1,ds)
	+ (xR(ds)) $(ord(mesh) eq N);

model qp / obj, rfv, rfvT, rfyL, rfy /;

uI.l(icontrols) = 0;
u.l(mesh,controls) = 0;
v.l(mesh,duals) = 0;
vT.l(tduals) = 0;
x.l(mesh, states) = 0;
xR.l(states) = 0;
v.l(mesh, duals) = 0;
vT.l(tduals) = 0;
vv.l(mesh,duals) = 0;
vvT.l(tduals) = 0;
vTdup.l(tduals) = 0;
vTdlo.l(tduals) = 0;
vdup.l(mesh,duals) = 0;
vdlo.l(mesh,duals) = 0;
z.l = 999999999;

option iterlim = 60000;
option reslim = 36000;		/* 10 hours */

* solve qp using nlp minimizing z;

put qpf_obj;
put "ELQP   primals:" pcount:5:0 "    duals:" dcount:5:0 /;
put "objective function value: " z.l:15:8 /;

put qpf;
$include "put.mns"
