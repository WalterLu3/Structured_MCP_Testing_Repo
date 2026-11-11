***********************************************
* written by GAMS/JAMS at 11/08/26 17:18:56
* for more information use JAMS option "Dict"
***********************************************

Variables  x1,x2,x3,x4,x5,x6,x7,x8,u9,u10,u11,u12,u13,u14,u15,u16;

Negative Variables  u12,u13,u14;

Positive Variables  x1,x2,x3,x4,x5,x6,x7,x8;

Positive Variables  u9,u10,u11;

Equations  e1,e2,e3,e4,e5,e6,e7,e8,e9,e10,e11,e12,e13,e14,e15,e16;


e1..    eps*x1 - u12 - u15 =N= 0;

e2..    eps*x2 - u13 - u15 =N= 0;

e3..    eps*x3 - u13 - u16 =N= 0;

e4..    eps*x4 - u14 - u16 =N= 0;

e5..    eps*x5 - u9 + u15 =N= 0;

e6..    eps*x6 - u10 + u15 =N= 0;

e7..    eps*x7 - u10 + u16 =N= 0;

e8..    eps*x8 - u11 + u16 =N= 0;

e9..    x5 =G= 10;

e10..    x6 + x7 =G= 20;

e11..    x8 =G= 30;

e12..    x1 =L= 20;

e13..    x2 + x3 =L= 20;

e14..    x4 =L= 20;

e15..    x1 + x2 - x5 - x6 =E= 0;

e16..    x3 + x4 - x7 - x8 =E= 0;

* set non-default bounds
x1.up = 30;
x2.up = 20;
x3.up = 10;
x4.up = 10;
x5.up = 10;
x6.up = 2;
x7.up = 20;
x8.up = 30;

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
