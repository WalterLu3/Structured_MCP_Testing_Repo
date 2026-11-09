***********************************************
* written by GAMS/JAMS at 11/08/26 17:19:03
* for more information use JAMS option "Dict"
***********************************************

Variables  x1,x2,x3,x4,x5,x6,x7,x8,u9,u10,u11,u12,u13,u14,u15,u16,u17,u18,u19;

Negative Variables  u13,u14,u15,u16,u17;

Positive Variables  x1,x2,x3,x4,x5,x6,x7,x8;

Positive Variables  u9,u10,u11,u12;

Equations  e1,e2,e3,e4,e5,e6,e7,e8,e9,e10,e11,e12,e13,e14,e15,e16,e17,e18,e19;


e1..    eps*x1 - u14 =N= 0;

e2..    eps*x2 + u9 + u10 - u12 - u18 - u19 =N= -1;

e3..    eps*x3 - u9 - 0.8*u13 - u16 + 0.05*u18 + 0.04*u19 =N= -1;

e4..    eps*x4 - u10 - u13 + 0.05*u19 =N= -1;

e5..    eps*x5 + 3*u11 - 0.5*u17 =N= 0;

e6..    eps*x6 - 2*u15 - 0.6*u17 =N= 0;

e7..    eps*x7 - u11 =N= 0;

e8..    eps*x8 + u15 =N= 0;

e9..  - x2 + x3 =G= 50000;

e10..  - x2 + x4 =G= 87000;

e11..  - 3*x5 + x7 =G= 10000;

e12..    x2 =G= 80000;

e13..    0.8*x3 + x4 =L= 10000;

e14..    x1 =L= 90000;

e15..    2*x6 - x8 =L= 10000;

e16..    x3 =L= 50000;

e17..    0.5*x5 + 0.6*x6 =L= 300000;

e18..    x2 - 0.05*x3 =E= 5000;

e19..    x2 - 0.04*x3 - 0.05*x4 =E= 4500;

Model m / e1.x1,e2.x2,e3.x3,e4.x4,e5.x5,e6.x6,e7.x7,e8.x8,e9.u9,e10.u10
         ,e11.u11,e12.u12,e13.u13,e14.u14,e15.u15,e16.u16,e17.u17,e18.u18
         ,e19.u19 /;

m.limrow=0; m.limcol=0;

* Regenerate this instance's polyhedral row information before solving.
File linlibPolyFile / 'poly.txt' /;
linlibPolyFile.pc = 2;
Scalar linlibPolyRow;
put linlibPolyFile;
for (linlibPolyRow = 9 to 19,
    put 'e' linlibPolyRow:0:0 /;
);
putclose linlibPolyFile '';

Solve m using MCP;
