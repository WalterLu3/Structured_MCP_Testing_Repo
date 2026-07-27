***********************************************
* written by GAMS/JAMS at 01/31/24 17:48:42
* for more information use JAMS option "Dict"
***********************************************

Variables  x1,x2,x3,u4,u5,u6,u7,u8;

Negative Variables  u4,u7,u8;

Positive Variables  u5,u6;

Equations  e1,e2,e3,e4,e5,e6,e7,e8;


e1.. 5*x1*x1 - u4 - u5 - u6 - u7 - 2*u8 =N= -5;

e2.. -x2*x2 - u4 - u5 + u6 + u7 + 5*u8 =N= -2;

e3.. -x1*x3 - u8 =N= -5;

e4..    x1 + x2 =L= 1;

e5..    x1 + x2 =G= -1;

e6..    x1 - x2 =G= -1;

e7..    x1 - x2 =L= 1;

e8..    2*x1 - 5*x2 + x3 =L= 2;

Model m / e1.x1,e2.x2,e3.x3,e4.u4,e5.u5,e6.u6,e7.u7,e8.u8 /;



file polystructure / 'poly.txt' /;
put polystructure;
put 'e4'/;
put 'e5'/;
put 'e6'/;
put 'e7'/;
put 'e8'/;
putclose polystructure;



option mcp=pathvicrash;

$onecho > pathvicrash.opt
crash_method pathvi
*proximal_perturbation 0
*crash_perturb 0 
pathvi_filename poly.txt
presolve 0
*lemke_start = always
*lemke_start_type = advanced
*output_minor_iterations_frequency=1
*output_initial_point_statistics=1
*output_linear_model=1
*major_iteration_limit=1
minor_iteration_limit=100000
output_warnings 0
$offecho

m.optfile = 1;


m.limrow=0; m.limcol=0;

Solve m using MCP;

display x1.l, x2.l, x3.l;
