
* ==> oc_bert.gms

$title An Optimal Control Problem from Bertsekas
$offsymxref offsymlist offuellist offuelxref
$inlinecom /* */

/* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  This file contains an Optimal Control problem from Bertsekas,
formulated as an MCP.  See

  D.P. Bertsekas, "Projected Newton Methods for Optimization Problems
with Simple Constraints", SIAM J. Control and Optimization 20 2, 1982,
p. 221-246.

We have the following continuous (primal) optimal control problem:

                  T
                integral [1/2 u(t)*P(t)*u(t) + 1/2 x(t)*Q(t)*x(t)] dt
                  0


        s.t.    (dx/dt)(t) = A(t)*x(t) + B(t)*u(t) + b(t),
                x(t_L) = x_0
                -1 <= u(t) <= 1

  where u(t) are the controls at time t and x(t) the state at time t.
  The dual, not given here, has state variables y(t) and controls v(t).

  For any N >= 1, the interval [O, T] is divided into N pieces by a
uniform mesh of N+1 points, including endpoints 0 and T. For the
primal problem, our discretization includes N+1 state vectors:
x^0, x^1, .. , x^N = x(T).  The control vectors at the first N mesh
points are u^1, .., u^N.  No control vector is needed for the right
endpoint.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% */

$if not setglobal dimension $setglobal dimension 1000
  
sets
mesh            / 1 * %dimension% /,	/* points 1 .. N in primal & dual mesh */
controls        / 1 * 1 /,      /* controls */
states          / 1 * 2 /,      /* states */
/* ds                              duals to states */
duals           / 1 * 8 /;      /* dual controls, or constraint multipliers */

alias   (ds, states),
        (controls, controls2),
        (duals, duals2);

scalar
T,                      /* time interval [0, T] */
N;                      /* number of grid (mesh) points */

T = 2;
N = card(mesh);

parameters
u_lo(controls) /
1       -1 /,
u_up(controls) /
1       1 /,
x0(states) /            /* state variables at t=0 */
1       15
2       5 /,

P(controls,controls2) /
1.1     6 /,
pp(controls) /
1       0 /,

Q(states,ds) /
1.1     2
2.2     1 /,
qq(states) /
1       0
2       0 /,

A(ds, states) /
1.2     1
2.1     -1 /,
B(ds, controls) /
1.1     0
2.1     1 /,
bb(ds);

/* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   The parameters are defined.  Now
   declare the variables and equations,
   and define the functions and the
   box constraints.
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% */


variables
u(mesh, controls),      /* control variables for [0,T) */
x(mesh, states),        /* state variables for (0,T] */
y(mesh, ds);            /* dual state vars, (0,T] */

u.lo(mesh,controls) = u_lo(controls);
u.up(mesh,controls) = u_up(controls);

u.l(mesh,controls) = (u_lo(controls) + u_up(controls)) / 2;

equations
delu(mesh, controls),
delx(mesh, states),
dely(mesh, ds);

delu(mesh, controls) ..
        ( sum(controls2, P(controls,controls2) * u(mesh,controls2))
          + pp(controls)
          + sum(ds, y(mesh,ds) * B(ds, controls)) * T
        ) / N
        =g= 0;
delx(mesh, states) ..
        ( sum(ds, Q(states,ds) * x(mesh,states))
          + qq(states)
          + sum(ds, y(mesh+1,ds) * A(ds,states)) * T
        ) / N
        + y(mesh+1,states)
        =e=
        y(mesh,states);

dely(mesh,ds) ..
        x(mesh,ds)
        =e=
        x(mesh-1,ds) + x0(ds)$(ord(mesh) eq 1) +
        ( sum(states, A(ds,states)*
           (x(mesh-1,states) + x0(states)$(ord(mesh) eq 1)))
          + sum(controls, B(ds,controls) * u(mesh,controls))
        ) * (T / N);

model bertoc   / delu.u, delx.x, dely.y /;

option limrow = 0;
option limcol = 0;
option solprint = off;
option iterlim = 2000;
option reslim = 900;            /* 4 hours */

file cp_obj /obj.pth/;
file qpf_obj /obj.mns/;

scalars
bindingc,
object;

x0("1") = 15;
x0("2") = 5;

u.l(mesh,controls) = 0;
x.l(mesh,states) = 0;
y.l(mesh,ds) = 0;

solve bertoc using mcp;

object = sum(mesh,
sum(controls, u.l(mesh,controls) * (pp(controls) +
        0.5*sum(controls2,P(controls,controls2)*u.l(mesh,controls2)) ) )
+ sum(states, x.l(mesh,states) * (qq(states) +
        0.5*sum(ds,Q(states,ds)*x.l(mesh,ds)) ) )
) * (T / N);
bindingc = sum(mesh,
 sum(controls$(u.l(mesh,controls) eq u_lo(controls) OR
	       u.l(mesh,controls) eq u_up(controls)),   1)
);

put cp_obj;
put " MCP solve" /;
put "T = " T:12:2 /;
put "N = " N:12:0 /;
put "s = " (T/N):12:9 /;
put "objective function value: " object:15:8 /;
put "    binding contstraints: " bindingc:15:0 / /;

u.l(mesh,controls) = u_up(controls);
x.l(mesh,states) = 0;
y.l(mesh,ds) = 0;

solve bertoc using mcp;

object = sum(mesh,
sum(controls, u.l(mesh,controls) * (pp(controls) +
        0.5*sum(controls2,P(controls,controls2)*u.l(mesh,controls2)) ) )
+ sum(states, x.l(mesh,states) * (qq(states) +
        0.5*sum(ds,Q(states,ds)*x.l(mesh,ds)) ) )
) * (T / N);
bindingc = sum(mesh,
 sum(controls$(u.l(mesh,controls) eq u_lo(controls) OR
	       u.l(mesh,controls) eq u_up(controls)),   1)
);

put cp_obj;
put " MCP solve" /;
put "T = " T:12:2 /;
put "N = " N:12:0 /;
put "s = " (T/N):12:9 /;
put "objective function value: " object:15:8 /;
put "    binding contstraints: " bindingc:15:0 / /;

x0("1") = 5;
x0("2") = -10;

u.l(mesh,controls) = 0;
x.l(mesh,states) = 0;
y.l(mesh,ds) = 0;

solve bertoc using mcp;

object = sum(mesh,
sum(controls, u.l(mesh,controls) * (pp(controls) +
        0.5*sum(controls2,P(controls,controls2)*u.l(mesh,controls2)) ) )
+ sum(states, x.l(mesh,states) * (qq(states) +
        0.5*sum(ds,Q(states,ds)*x.l(mesh,ds)) ) )
) * (T / N);
bindingc = sum(mesh,
 sum(controls$(u.l(mesh,controls) eq u_lo(controls) OR
	       u.l(mesh,controls) eq u_up(controls)),   1)
);

put cp_obj;
put " MCP solve" /;
put "T = " T:12:2 /;
put "N = " N:12:0 /;
put "s = " (T/N):12:9 /;
put "objective function value: " object:15:8 /;
put "    binding contstraints: " bindingc:15:0 / /;

u.l(mesh,controls) = u_up(controls);
x.l(mesh,states) = 0;
y.l(mesh,ds) = 0;

solve bertoc using mcp;

object = sum(mesh,
sum(controls, u.l(mesh,controls) * (pp(controls) +
        0.5*sum(controls2,P(controls,controls2)*u.l(mesh,controls2)) ) )
+ sum(states, x.l(mesh,states) * (qq(states) +
        0.5*sum(ds,Q(states,ds)*x.l(mesh,ds)) ) )
) * (T / N);
bindingc = sum(mesh,
 sum(controls$(u.l(mesh,controls) eq u_lo(controls) OR
	       u.l(mesh,controls) eq u_up(controls)),   1)
);

put cp_obj;
put " MCP solve" /;
put "T = " T:12:2 /;
put "N = " N:12:0 /;
put "s = " (T/N):12:9 /;
put "objective function value: " object:15:8 /;
put "    binding contstraints: " bindingc:15:0 / /;



/* start stuff for QP */
putclose cp_obj;

variables
z;              /* objective value */

equations
obj;

obj ..  z =e= sum(mesh,
sum(controls, u(mesh,controls) * (pp(controls) +
        0.5*sum(controls2,P(controls,controls2)*u(mesh,controls2)) ) )
+ sum(states, x(mesh,states) * (qq(states) +
        0.5*sum(ds,Q(states,ds)*x(mesh,ds)) ) )
) * (T / N);

model qp / obj, dely /;

u.l(mesh,controls) = 0;
x.l(mesh, states) = 0;
z.l = 999999999;

option iterlim = 6000;
option reslim = 3600;           /* 10 hours */

* solve qp using nlp minimizing z;

bindingc = sum(mesh,
 sum(controls$(u.l(mesh,controls) eq u_lo(controls) OR
	       u.l(mesh,controls) eq u_up(controls)),   1)
);

put qpf_obj;
put " QP solve" /;
put "objective function value: " z.l:15:8 /;
put "    binding contstraints: " bindingc:15:0 / /;
