
* ==>pies.gms

$TITLE PIES Energy Equilibrium
$offsymxref offsymlist offuellist offuelxref
$inlinecom /* */
/* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

A linear program with a variable rhs in the constraint system
is expressed as a complementarity problem.

LP:	min 	<c,x>
		Ax = q(p),
	s.t.	Bx = b,
		x >= 0

where the prices p are the duals to the first constraint.

MCP:	       A'p + B'v + c >= 0, x >= 0, comp.
	-Ax + q(p)           =  0, p free, comp.
	-Bx              + b =  0, v free, comp.

Of course, the variables x and v are going to be
split up further in the GAMS model.

References:
William W. Hogan, Energy Policy Models for Project Independence,
Computers \& Operations Research (2), 1975.

N. Josephy, A Newton Method for the PIES energy model,
Tech Report, Mathematics Research Center, UW-Madison, 1979.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% */

sets
run 	/ run1 * run8 /,
comod	/ C, L, H /,		/* coal and light and heavy oil */
R	/ C, S /,		/* resources (capital, steel) */
creg	/ 1 * 2 /,		/* coal producing regions */
oreg	/ 1 * 2 /,		/* crude oil producing regions */
ctyp	/ 1 * 3 /,		/* increments of coal production */
otyp	/ 1 * 2 /,		/* increments of oil production */
refin	/ 1 * 2 /,		/* refineries */
users	/ 1 * 2 /;		/* consumption regions */

alias (comod,cc);

parameters
rmax(R) /		/* maximum resource usage */
C	35000
S	12000
/,
cmax(creg,ctyp) /	/* coal prod. limits */
1.1	300
1.2	300
1.3	400
2.1	200
2.2	300
2.3	600
/,
omax(oreg,otyp) /	/* oil prod. limits */
1.1	1100
1.2	1200
2.1	1300
2.2	1100
/,
rcost(refin) /		/* refining cost */
1	6.5
2	5
/,
q0(comod) /		/* base demand for commodities */
C	1000
L	1200
H	1000
/,
p0(comod) /		/* base prices for commodities */
C	12
L	16
H	12
/,
demand(comod,users),	/* computed at optimality */
output(refin,*) /	/* % output of light/heavy oil */
1.L	.6
1.H	.4
2.L	.5
2.H	.5
/;

table esub(comod,cc)	/* cross-elasticities of substitution */
	C	L	H
C	-.75	.1	.2
L	.1	-.5	.2
H	.2	.1	-.5 ;

table cruse(R,creg,ctyp) /* resource use in coal prod */
	1	2	3
C.1	1	5	10
C.2	1	5	6
S.1	1	2	3
S.2	1	4	5 ;

table oruse(R,oreg,otyp) /* resource use in oil prod */
	1	2
C.1	0	10
C.2	0	15
S.1	0	4
S.2	0	2 ;

table ccost(creg,ctyp)	/* coal prod. cost */
	1	2	3
1	5	6	8
2	4	5	7 ;

table ocost(oreg,otyp)	/* oil prod. cost */
	1	2
1	1	1.5
2	1.25	1.5 ;

table ctcost(creg,users)
	1	2
1	1	2.5
2	.75	2.75 ;

table otcost(oreg,refin)
	1	2
1	2	3
2	4	2 ;

table ltcost(refin,users)	/* light oil trans costs */
	1	2
1	1	1.2
2	1	1.5 ;

table htcost(refin,users)	/* heavy oil trans costs */
	1	2
1	1	1.2
2	1	1.5 ;


positive variables
c(creg,ctyp),		/* coal production */
o(oreg,otyp),		/* oil production */
ct(creg,users),		/* coal transportation levels */
ot(oreg,refin),		/* crude oil transportation levels */
lt(refin,users),	/* light transportation levels */
ht(refin,users),	/* heavy transportation levels */
p(comod,users),		/* commodity prices */
mu(R);			/* dual to ruse cons.; marginal utility */

positive variables
cv(creg),		/* dual to cmbal */
ov(oreg),
lv(refin),
hv(refin);

c.up(creg,ctyp) = cmax(creg,ctyp);
o.up(oreg,otyp) = omax(oreg,otyp);

equations
delc(creg, ctyp),
delo(oreg, otyp),
delct(creg,users),
delot(oreg,refin),
dellt(refin,users),
delht(refin,users),
dembal(comod,users),		/* excess supply of product */
cmbal(creg),			/* coal material balance */
ombal(oreg),			/* oil material balance */
lmbal(refin),			/* light material balance */
hmbal(refin),			/* heavy material balance */
ruse(R);			/* resource use constraints */

delc(creg,ctyp) ..
  ccost(creg,ctyp) + sum(R, cruse(R,creg,ctyp)*mu(R))
  =g=   cv(creg);

delo(oreg,otyp) ..
  ocost(oreg,otyp) + sum(R, oruse(R,oreg,otyp)*mu(R))
  =g=   ov(oreg);

delct(creg,users) ..
  ctcost(creg,users) + cv(creg)  =g=  p("C",users);

delot(oreg,refin) ..
  otcost(oreg,refin) + rcost(refin) + ov(oreg)   =g=
  output(refin,"L") * lv(refin) + output(refin,"H") * hv(refin);

dellt(refin,users) ..
  ltcost(refin,users) + lv(refin)
  =g=  p("L",users);

delht(refin,users) ..
  htcost(refin,users) + hv(refin)
  =g=  p("H",users);

dembal(comod,users) ..
  (sum(creg,ct(creg,users)))$(ord(comod) eq 1)
  + (sum(refin,lt(refin,users)))$(ord(comod) eq 2)
  + (sum(refin,ht(refin,users)))$(ord(comod) eq 3)
  =g=
  q0(comod) * prod(cc, (p(cc,users)/p0(cc))**esub(comod,cc));

cmbal(creg) ..
  sum(ctyp,c(creg,ctyp))  =e=  sum(users,ct(creg,users));
  
ombal(oreg) ..
  sum(otyp,o(oreg,otyp))  =e=  sum(refin,ot(oreg,refin));

lmbal(refin) ..
  sum(oreg, ot(oreg,refin)) * output(refin,"L") =e=
  sum(users,lt(refin,users));

hmbal(refin) ..
  sum(oreg, ot(oreg,refin)) * output(refin,"H") =e=
  sum(users,ht(refin,users));

ruse(R) ..
  rmax(R) =g=
  sum(creg, sum(ctyp, c(creg,ctyp)*cruse(R,creg,ctyp)))
  + sum(oreg, sum(otyp, o(oreg,otyp)*oruse(R,oreg,otyp)));


model pies / delc.c, delo.o, delct.ct, delot.ot, dellt.lt, delht.ht,
	dembal.p, cmbal.cv, ombal.ov, lmbal.lv, hmbal.hv, ruse.mu /;

option limrow = 0;
option limcol = 0;
option iterlim = 1000;
option reslim = 120;

table i_c(creg,ctyp)
	1	2	3
1	300	300	400
2	200	300	600 ;

table i_o(oreg,otyp)
	1	2
1	1100	1000
2	1300	1000 ;

table i_ct(creg,users)	/* initial trans */
	1	2
1	0	828
2	1016	84 ;

table i_ot(oreg,refin)	/* initial trans */
	1	2
1	2075	0
2	0	2358 ;

table i_lt(refin,users)	/* initial trans */
	1	2
1	22	1223
2	1179	0 ;

table i_ht(refin,users)	/* initial trans */
	1	2
1	0	830
2	998	180 ;

table iprice(comod,users)	/* initial price estimate */
	1	2
C	11.7	13.7
L	15.8	16.0
H	11.9	12.4 ;

c.l(creg,ctyp) = i_c(creg,ctyp);
o.l(oreg,otyp) = i_o(oreg,otyp);
ct.l(creg,users) = i_ct(creg,users);
ot.l(oreg,refin) = i_ot(oreg,refin);
lt.l(refin,users) = i_lt(refin,users);
ht.l(refin,users) = i_ht(refin,users);
p.lo(comod,users) = .1;
* p.fx(comod,users) = iprice(comod,users);
p.l(comod,users) = iprice(comod,users);

cv.l(creg) = 1;
ov.l(oreg) = 1;
lv.l(refin) = 1;
hv.l(refin) = 1;
mu.l(R) = 1;

file polystructure / 'poly.txt' /;
put polystructure;
loop ( creg,
  put cmbal(creg)/;
);
loop ( oreg,
  put ombal(oreg)/;
);

loop ( refin,
  put lmbal(refin)/;
  put hmbal(refin)/;
);

loop (R , 
  put ruse(R)/;
);

putclose polystructure;

solve pies using mcp;

file  out /pies.out/;
put out;

put "Coal Prod:      type 1     type 2     type 3" /;
put "region 1   ", c.l("1","1"):11:3, c.l("1","2"):11:3, c.l("1","3"):11:3 /;
put "region 2   ", c.l("2","1"):11:3, c.l("2","2"):11:3, c.l("2","3"):11:3 /;
put /;
put "Oil Prod:       type 1     type 2" /;
put "region 1   ", o.l("1","1"):11:3, o.l("1","2"):11:3 /;
put "region 2   ", o.l("2","1"):11:3, o.l("2","2"):11:3 /;
put /;
put "Coal Trans:     user 1     user 2" /;
put "region 1   ", ct.l("1","1"):11:3, ct.l("1","2"):11:3 /;
put "region 2   ", ct.l("2","1"):11:3, ct.l("2","2"):11:3 /;
put /;
put "Oil Trans:     refin 1    refin 2" /;
put "region 1   ", ot.l("1","1"):11:3, ot.l("1","2"):11:3 /;
put "region 2   ", ot.l("2","1"):11:3, ot.l("2","2"):11:3 /;
put /;
put "Light Trans:    user 1     user 2" /;
put "refin 1    ", lt.l("1","1"):11:3, lt.l("1","2"):11:3 /;
put "refin 2    ", lt.l("2","1"):11:3, lt.l("2","2"):11:3 /;
put /;
put "Heavy Trans:    user 1     user 2" /;
put "refin 1    ", ht.l("1","1"):11:3, ht.l("1","2"):11:3 /;
put "refin 2    ", ht.l("2","1"):11:3, ht.l("2","2"):11:3 /;
put /;
put "Prices:         user 1     user 2" /;
put "Coal       ", p.l("C","1"):11:3, p.l("C","2"):11:3 /;
put "Light oil  ", p.l("L","1"):11:3, p.l("L","2"):11:3 /;
put "Heavy oil  ", p.l("H","1"):11:3, p.l("H","2"):11:3 /;
put /;
demand(comod,users) = q0(comod) *
	 prod(cc, (p.l(cc,users)/p0(cc))**esub(comod,cc));
put "Demand:         user 1     user 2" /;
put "Coal       ", demand("C","1"):11:3, demand("C","2"):11:3 /;
put "Light oil  ", demand("L","1"):11:3, demand("L","2"):11:3 /;
put "Heavy oil  ", demand("H","1"):11:3, demand("H","2"):11:3 /;
put /;
put "Capital usage: ", (0-ruse.l("C")):10:2, "    dual price: ", mu.l("C"):9:3 /;
put "  Steel usage: ", (0-ruse.l("S")):10:2, "    dual price: ", mu.l("S"):9:3 /;
