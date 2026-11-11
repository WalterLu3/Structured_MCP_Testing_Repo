***********************************************
* written by GAMS/JAMS at 11/08/26 17:19:13
* for more information use JAMS option "Dict"
***********************************************

Variables  x1,x2,x3,x4,u5,u6,u7,u8;

Negative Variables  u5,u6,u7,u8;

Positive Variables  x1,x2,x3,x4;

Equations  e1,e2,e3,e4,e5,e6,e7,e8;


e1..    eps*x1 - u5 - 20*u6 - 200*u7 - 2000*u8 =N= 1000;

e2..    eps*x2 - u6 - 20*u7 - 200*u8 =N= 100;

e3..    eps*x3 - u7 - 20*u8 =N= 10;

e4..    eps*x4 - u8 =N= 1;

e5..    x1 =L= 1;

e6..    20*x1 + x2 =L= 100;

e7..    200*x1 + 20*x2 + x3 =L= 10000;

e8..    2000*x1 + 200*x2 + 20*x3 + x4 =L= 1000000;

Model m / e1.x1,e2.x2,e3.x3,e4.x4,e5.u5,e6.u6,e7.u7,e8.u8 /;

m.limrow=0; m.limcol=0;

* Regenerate this instance's polyhedral row information before solving.
File linlibPolyFile / 'poly.txt' /;
linlibPolyFile.pc = 2;
Scalar linlibPolyRow;
put linlibPolyFile;
for (linlibPolyRow = 5 to 8,
    put 'e' linlibPolyRow:0:0 /;
);
putclose linlibPolyFile '';

Solve m using MCP;
