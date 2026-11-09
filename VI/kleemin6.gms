***********************************************
* written by GAMS/JAMS at 11/08/26 17:19:13
* for more information use JAMS option "Dict"
***********************************************

Variables  x1,x2,x3,x4,x5,x6,u7,u8,u9,u10,u11,u12;

Negative Variables  u7,u8,u9,u10,u11,u12;

Positive Variables  x1,x2,x3,x4,x5,x6;

Equations  e1,e2,e3,e4,e5,e6,e7,e8,e9,e10,e11,e12;


e1..    eps*x1 - u7 - 20*u8 - 200*u9 - 2000*u10 - 20000*u11 - 200000*u12
      =N= 100000;

e2..    eps*x2 - u8 - 20*u9 - 200*u10 - 2000*u11 - 20000*u12 =N= 10000;

e3..    eps*x3 - u9 - 20*u10 - 200*u11 - 2000*u12 =N= 1000;

e4..    eps*x4 - u10 - 20*u11 - 200*u12 =N= 100;

e5..    eps*x5 - u11 - 20*u12 =N= 10;

e6..    eps*x6 - u12 =N= 1;

e7..    x1 =L= 1;

e8..    20*x1 + x2 =L= 100;

e9..    200*x1 + 20*x2 + x3 =L= 10000;

e10..    2000*x1 + 200*x2 + 20*x3 + x4 =L= 1000000;

e11..    20000*x1 + 2000*x2 + 200*x3 + 20*x4 + x5 =L= 100000000;

e12..    200000*x1 + 20000*x2 + 2000*x3 + 200*x4 + 20*x5 + x6 =L= 10000000000;

Model m / e1.x1,e2.x2,e3.x3,e4.x4,e5.x5,e6.x6,e7.u7,e8.u8,e9.u9,e10.u10
         ,e11.u11,e12.u12 /;

m.limrow=0; m.limcol=0;

* Regenerate this instance's polyhedral row information before solving.
File linlibPolyFile / 'poly.txt' /;
linlibPolyFile.pc = 2;
Scalar linlibPolyRow;
put linlibPolyFile;
for (linlibPolyRow = 7 to 12,
    put 'e' linlibPolyRow:0:0 /;
);
putclose linlibPolyFile '';

Solve m using MCP;
