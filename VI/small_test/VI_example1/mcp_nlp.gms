***********************************************
* written by GAMS/JAMS at 01/31/24 13:32:30
* for more information use JAMS option "Dict"
***********************************************
option mcp=pathvicrash;


Variables  x1,x2,u3,u4,u5,u6;

Negative Variables  u3,u6;

Positive Variables  u4,u5;

Equations  e1,e2,e3,e4,e5,e6;


e1.. 5*x1*x1 - u3 - u4 - u5 - u6 =N= -5;

e2.. -x2*x2 - u3 - u4 + u5 + u6 =N= -2;

e3..    x1 + x2 =L= 1;

e4..    x1 + x2 =G= -1;

e5..    x1 - x2 =G= -1;

e6..    x1 - x2 =L= 1;

Model m / e1.x1,e2.x2,e3.u3,e4.u4,e5.u5,e6.u6 /;


* put in the polyhedral information
file polystructure / 'poly.txt' /;
put polystructure;
put 'e3'/;
put 'e4'/;
put 'e5'/;
put 'e6'/;
putclose polystructure;

option mcp=pathvicrash;

$onecho > pathvicrash.opt
crash_method pathvi
proximal_perturbation=0
crash_perturb 0 
pathvi_filename poly.txt
presolve 0
*lemke_start=automatic
*lemke_start_type=advanced
*output_minor_iterations_frequency=1
*output_initial_point_statistics=1
*output_linear_model=1
$offecho

m.limrow=0; m.limcol=0;

m.optfile = 1;
Solve m using MCP;
