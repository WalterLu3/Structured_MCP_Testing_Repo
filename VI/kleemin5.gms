***********************************************
* written by GAMS/JAMS at 11/08/26 17:19:13
* for more information use JAMS option "Dict"
***********************************************

Variables  x1,x2,x3,x4,x5,u6,u7,u8,u9,u10;

Negative Variables  u6,u7,u8,u9,u10;

Positive Variables  x1,x2,x3,x4,x5;

Equations  e1,e2,e3,e4,e5,e6,e7,e8,e9,e10;


e1..    eps*x1 - u6 - 20*u7 - 200*u8 - 2000*u9 - 20000*u10 =N= 10000;

e2..    eps*x2 - u7 - 20*u8 - 200*u9 - 2000*u10 =N= 1000;

e3..    eps*x3 - u8 - 20*u9 - 200*u10 =N= 100;

e4..    eps*x4 - u9 - 20*u10 =N= 10;

e5..    eps*x5 - u10 =N= 1;

e6..    x1 =L= 1;

e7..    20*x1 + x2 =L= 100;

e8..    200*x1 + 20*x2 + x3 =L= 10000;

e9..    2000*x1 + 200*x2 + 20*x3 + x4 =L= 1000000;

e10..    20000*x1 + 2000*x2 + 200*x3 + 20*x4 + x5 =L= 100000000;

Model m / e1.x1,e2.x2,e3.x3,e4.x4,e5.x5,e6.u6,e7.u7,e8.u8,e9.u9,e10.u10 /;

m.limrow=0; m.limcol=0;

* Regenerate this instance's polyhedral row information before solving.
File linlibPolyFile / 'poly.txt' /;
linlibPolyFile.pc = 2;
Scalar linlibPolyRow;
put linlibPolyFile;
for (linlibPolyRow = 6 to 10,
    put 'e' linlibPolyRow:0:0 /;
);
putclose linlibPolyFile '';

Solve m using MCP;
