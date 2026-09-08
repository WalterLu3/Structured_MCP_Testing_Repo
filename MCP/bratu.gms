
*==>bratu.gms

$TITLE The Obstacle Bratu Problem
$offsymxref offsymlist offuellist offuelxref
$inlinecom /* */

/* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  Nonlinear complementarity problem:
  find a function $u$ defined on D=(0,1) x (0,1) such that
  -\Delta u - lambda exp(u) <= 0,   u <= \psi, complementarity
  holds on D and u = 0 on dD.

  This problem can be obtained by using a non-linear force exp(u)
  on the membrane in the obstacle problem (see obstacle.gms),
  and using a trivial lower obstacle.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% */

$if not setglobal dimension $setglobal dimension 76

sets
I	/ 0 * %dimension% /,
J	/ 0 * %dimension% /;

scalars
xlo	/ 0 /,
xhi	/ 1 /,
ylo	/ 0 /,
yhi	/ 1 /,
dx,
dy,
lambda	/ 10 /;		/* force parameter, force = lambda*exp(v) */

dx = (xhi - xlo) / (card(I)-1);
dy = (yhi - ylo) / (card(J)-1);

parameters
lb(I,J),
ub(I,J);


variables
v(I,J);		/* height of membrane */

equations
dv(I,J);

dv(I,J) ..
  (dy/dx) * (2*v(I,J) - v(I+1,J) - v(I-1,J))
+ (dx/dy) * (2*v(I,J) - v(I,J+1) - v(I,J-1))
=g=
lambda * exp(v(I,J)) * dx * dy;

model obst	/ dv.v /;


option solprint = off;
option limrow = 0;
option limcol = 0;
option iterlim = 100000;
option reslim = 36000;

$ontext
/* problem with a ball constraining from above */
scalar
midI, midJ,
cheight		/ .55 /,	/* height of center of ball */
ball_rad	/ 0.5 /;


midI = (card(I) + 1) / 2;
midJ = (card(J) + 1) / 2;
* use lb as temp 
lb(I,J) = ( power(ord(I)-midI,2) + power(ord(J)-midJ,2) ) /
		(midI*midI + midJ*midJ) ;
ub(I,J) = min (2000, cheight - ball_rad*sqrt(1-lb(I,J)) );
lb(I,J) = 0;
$offtext

lb(I,J) = 0;
ub(I,J) = 1;

/* the position v is fixed at zero on the boundary */
ub(I,J)$(ord(J) eq card(J) OR ord(J) eq 1) = 0;
ub(I,J)$(ord(I) eq card(I) OR ord(I) eq 1) = 0;
lb(I,J)$(ord(J) eq card(J) OR ord(J) eq 1) = 0;
lb(I,J)$(ord(I) eq card(I) OR ord(I) eq 1) = 0;

file membrane / bratu.dat /;
file solu     / bratu.sol /;

v.lo(I,J) = lb(I,J);
v.up(I,J) = ub(I,J);
v.l(I,J) = (ub(I,J) + lb(I,J)) / 2;
* v.l(I,J) = lb(I,J);
* v.l(I,J) = ub(I,J);

* $include "bratu.sol"

solve obst using mcp;

put membrane;

put card(I) / card(J) /;
loop (I,
    loop (J,
	put v.l(I,J):12:6 /;
	);
    put /;
);

put solu;

put "parameter vinit(I,J) /" /;
loop (I,
    loop (J,
	put I.tl:3, "." J.tl:3, " ", v.l(I,J):10:6 /;
         );
     );
put "/;" /;
put "v.l(I,J) = vinit(I,J);"
