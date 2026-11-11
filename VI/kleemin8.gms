***********************************************
* written by GAMS/JAMS at 11/08/26 17:19:13
* for more information use JAMS option "Dict"
***********************************************

Variables  x1,x2,x3,x4,x5,x6,x7,x8,u9,u10,u11,u12,u13,u14,u15,u16;

Negative Variables  u9,u10,u11,u12,u13,u14,u15,u16;

Positive Variables  x1,x2,x3,x4,x5,x6,x7,x8;

Equations  e1,e2,e3,e4,e5,e6,e7,e8,e9,e10,e11,e12,e13,e14,e15,e16;


e1..    eps*x1 - u9 - 20*u10 - 200*u11 - 2000*u12 - 20000*u13 - 200000*u14
      - 2000000*u15 - 20000000*u16 =N= 10000000;

e2..    eps*x2 - u10 - 20*u11 - 200*u12 - 2000*u13 - 20000*u14 - 200000*u15
      - 2000000*u16 =N= 1000000;

e3..    eps*x3 - u11 - 20*u12 - 200*u13 - 2000*u14 - 20000*u15 - 200000*u16
      =N= 100000;

e4..    eps*x4 - u12 - 20*u13 - 200*u14 - 2000*u15 - 20000*u16 =N= 10000;

e5..    eps*x5 - u13 - 20*u14 - 200*u15 - 2000*u16 =N= 1000;

e6..    eps*x6 - u14 - 20*u15 - 200*u16 =N= 100;

e7..    eps*x7 - u15 - 20*u16 =N= 10;

e8..    eps*x8 - u16 =N= 1;

e9..    x1 =L= 1;

e10..    20*x1 + x2 =L= 100;

e11..    200*x1 + 20*x2 + x3 =L= 10000;

e12..    2000*x1 + 200*x2 + 20*x3 + x4 =L= 1000000;

e13..    20000*x1 + 2000*x2 + 200*x3 + 20*x4 + x5 =L= 100000000;

e14..    200000*x1 + 20000*x2 + 2000*x3 + 200*x4 + 20*x5 + x6 =L= 10000000000;

e15..    2000000*x1 + 200000*x2 + 20000*x3 + 2000*x4 + 200*x5 + 20*x6 + x7
       =L= 1000000000000;

e16..    20000000*x1 + 2000000*x2 + 200000*x3 + 20000*x4 + 2000*x5 + 200*x6
       + 20*x7 + x8 =L= 100000000000000;

Model m / e1.x1,e2.x2,e3.x3,e4.x4,e5.x5,e6.x6,e7.x7,e8.x8,e9.u9,e10.u10
         ,e11.u11,e12.u12,e13.u13,e14.u14,e15.u15,e16.u16 /;

m.limrow=0; m.limcol=0;

* Regenerate this instance's polyhedral row information before solving.
File linlibPolyFile / 'poly.txt' /;
linlibPolyFile.pc = 2;
Scalar linlibPolyRow;
put linlibPolyFile;
for (linlibPolyRow = 9 to 16,
    put 'e' linlibPolyRow:0:0 /;
);
putclose linlibPolyFile '';

Solve m using MCP;
