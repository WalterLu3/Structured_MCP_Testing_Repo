***********************************************
* written by GAMS/JAMS at 11/08/26 17:18:29
* for more information use JAMS option "Dict"
***********************************************

Variables  x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,u13,u14,u15,u16,u17,u18,u19;

Negative Variables  u13,u14,u15,u16,u17;

Positive Variables  x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12;

Equations  e1,e2,e3,e4,e5,e6,e7,e8,e9,e10,e11,e12,e13,e14,e15,e16,e17,e18,e19;


e1..    eps*x1 - 4*u13 - u14 - 20*u15 =N= -346;

e2..    eps*x2 - 4*u13 - u14 - 15*u15 - 40*u18 =N= -346;

e3..    eps*x3 - 2*u13 - u14 =N= -248;

e4..    eps*x4 - 2*u13 - u14 - 35*u18 =N= -248;

e5..    eps*x5 - u13 - u14 - u19 =N= -399;

e6..    eps*x6 - u13 - u14 - 50*u18 =N= -399;

e7..    eps*x7 - 250*u13 - 2*u14 - 30*u15 - u16 =N= -200;

e8..    eps*x8 - 250*u13 - 2*u14 - u16 - 15*u18 =N= -200;

e9..    eps*x9 - 125*u13 - u14 - 20*u15 - u17 =N= -75;

e10..    eps*x10 - 125*u13 - u14 - u17 - 10*u18 =N= -75;

e11..    eps*x11 - u15 =N= -2.35;

e12..    eps*x12 - u18 =N= -3.5;

e13..    4*x1 + 4*x2 + 2*x3 + 2*x4 + x5 + x6 + 250*x7 + 250*x8 + 125*x9
       + 125*x10 =L= 25000;

e14..    x1 + x2 + x3 + x4 + x5 + x6 + 2*x7 + 2*x8 + x9 + x10 =L= 300;

e15..    20*x1 + 15*x2 + 30*x7 + 20*x9 + x11 =L= 1500;

e16..    x7 + x8 =L= 50;

e17..    x9 + x10 =L= 100;

e18..    40*x2 + 35*x4 + 50*x6 + 15*x8 + 10*x10 + x12 =E= 5000;

e19..    x5 =E= 0;

Model m / e1.x1,e2.x2,e3.x3,e4.x4,e5.x5,e6.x6,e7.x7,e8.x8,e9.x9,e10.x10
         ,e11.x11,e12.x12,e13.u13,e14.u14,e15.u15,e16.u16,e17.u17,e18.u18
         ,e19.u19 /;

m.limrow=0; m.limcol=0;

* Regenerate this instance's polyhedral row information before solving.
File linlibPolyFile / 'poly.txt' /;
linlibPolyFile.pc = 2;
Scalar linlibPolyRow;
put linlibPolyFile;
for (linlibPolyRow = 13 to 19,
    put 'e' linlibPolyRow:0:0 /;
);
putclose linlibPolyFile '';

Solve m using MCP;
