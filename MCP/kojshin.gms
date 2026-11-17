$if not set run $set run 1
$ifthen set listOpts
$log option: run = %run%
$endif

*==> kojshin.gms

$TITLE KOJIMA/SHINDO
$offsymxref offsymlist offuellist offuelxref
$inlinecom /* */

/* ****************************************************************

This simple four-variable problem was given by:
M. Kojima and S. Shindo, "Extensions of Newton and Quasi-Newton
Method to PC^1 equations", Journal of Operations Research Society of
Japan (29) p352-374.

Two solutions: x1 = (1.2247, 0, 0, 0.5), x2 = (1, 0, 3, 0).

******************************************************************* */

sets
run	/ run1 * run8 /,
J	/ 1 * 4 / ;
alias (J,I);

table initpt (J,run)
	run1	run2	run3	run4	run5	run6	run7	run8
1		1	100	1	1			1.25
2		1	100			1	1	
3		1	100	1		1	0	
4		1	100				1	0.5	;

positive variables
	 x(J);

equations
	 f(I);

f(I) ..    
	(3*sqr(x("1"))+2*x("1")*x("2")+2*sqr(x("2"))+x("3")+3*x("4")-6
         )$(ord(I) eq 1)
	+ (2*sqr(x("1"))+x("1")+sqr(x("2"))+10*x("3")+2*x("4")-2)$(ord(I) eq 2)
	+ (3*sqr(x("1"))+x("1")*x("2")+2*sqr(x("2"))+2*x("3")+9*x("4")-9
	   )$(ord(I) eq 3)
	+ (sqr(x("1"))+3*sqr(x("2"))+2*x("3")+3*x("4")-3)$(ord(I) eq 4) 
	=g= 0;

model kojshin / f.x /;

x.l(J) = initpt(J,'run%run%');
solve kojshin using mcp;

