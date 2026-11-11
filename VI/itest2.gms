***********************************************
* written by GAMS/JAMS at 11/08/26 17:19:03
* for more information use JAMS option "Dict"
***********************************************

Variables  x1,x2,x3,x4,u5,u6,u7,u8,u9,u10,u11,u12,u13;

Negative Variables  u9,u10,u11,u12,u13;

Positive Variables  x1,x2,x3,x4;

Positive Variables  u5,u6,u7,u8;

Equations  e1,e2,e3,e4,e5,e6,e7,e8,e9,e10,e11,e12,e13;


e1..    eps*x1 + 0.5*u5 - 2*u6 - 3*u9 - u12 - u13 =N= 0;

e2..    eps*x2 - u5 + u6 - u8 - u9 - 2*u13 =N= 0;

e3..    eps*x3 - u7 - u8 - 3*u11 - u13 =N= 0;

e4..    eps*x4 - u10 + u11 - u12 =N= 0;

e5..  - 0.5*x1 + x2 =G= 0.5;

e6..    2*x1 - x2 =G= 3;

e7..    x3 =G= 5;

e8..    x2 + x3 =G= 1;

e9..    3*x1 + x2 =L= 6;

e10..    x4 =L= 2;

e11..    3*x3 - x4 =L= 2;

e12..    x1 + x4 =L= 10;

e13..    x1 + 2*x2 + x3 =L= 14;

Model m / e1.x1,e2.x2,e3.x3,e4.x4,e5.u5,e6.u6,e7.u7,e8.u8,e9.u9,e10.u10
         ,e11.u11,e12.u12,e13.u13 /;

m.limrow=0; m.limcol=0;

* Regenerate this instance's polyhedral row information before solving.
File linlibPolyFile / 'poly.txt' /;
linlibPolyFile.pc = 2;
Scalar linlibPolyRow;
put linlibPolyFile;
for (linlibPolyRow = 5 to 13,
    put 'e' linlibPolyRow:0:0 /;
);
putclose linlibPolyFile '';

Solve m using MCP;
