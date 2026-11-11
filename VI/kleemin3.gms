***********************************************
* written by GAMS/JAMS at 11/08/26 17:19:13
* for more information use JAMS option "Dict"
***********************************************

Variables  x1,x2,x3,u4,u5,u6;

Negative Variables  u4,u5,u6;

Positive Variables  x1,x2,x3;

Equations  e1,e2,e3,e4,e5,e6;


e1..    eps*x1 - u4 - 20*u5 - 200*u6 =N= 100;

e2..    eps*x2 - u5 - 20*u6 =N= 10;

e3..    eps*x3 - u6 =N= 1;

e4..    x1 =L= 1;

e5..    20*x1 + x2 =L= 100;

e6..    200*x1 + 20*x2 + x3 =L= 10000;

Model m / e1.x1,e2.x2,e3.x3,e4.u4,e5.u5,e6.u6 /;

m.limrow=0; m.limcol=0;

* Regenerate this instance's polyhedral row information before solving.
File linlibPolyFile / 'poly.txt' /;
linlibPolyFile.pc = 2;
Scalar linlibPolyRow;
put linlibPolyFile;
for (linlibPolyRow = 4 to 6,
    put 'e' linlibPolyRow:0:0 /;
);
putclose linlibPolyFile '';

Solve m using MCP;
