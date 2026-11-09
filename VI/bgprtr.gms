***********************************************
* written by GAMS/JAMS at 11/08/26 17:17:50
* for more information use JAMS option "Dict"
***********************************************

Variables  x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16,x17,x18,x19
          ,x20,x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,x31,x32,x33,x34,u35,u36
          ,u37,u38,u39,u40,u41,u42,u43,u44,u45,u46,u47,u48,u49,u50,u51,u52,u53
          ,u54;

Negative Variables  u35,u36,u37,u38,u39,u40;

Positive Variables  x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16,x17
          ,x18,x19,x20,x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,x31,x32,x33,x34;

Equations  e1,e2,e3,e4,e5,e6,e7,e8,e9,e10,e11,e12,e13,e14,e15,e16,e17,e18,e19
          ,e20,e21,e22,e23,e24,e25,e26,e27,e28,e29,e30,e31,e32,e33,e34,e35,e36
          ,e37,e38,e39,e40,e41,e42,e43,e44,e45,e46,e47,e48,e49,e50,e51,e52,e53
          ,e54;


e1..    eps*x1 - u41 - u47 =N= -29970;

e2..    eps*x2 - u42 - u48 =N= -29970;

e3..    eps*x3 - u41 - u49 =N= -29910;

e4..    eps*x4 - u42 - u50 =N= -29910;

e5..    eps*x5 - u39 + u43 =N= 1000;

e6..    eps*x6 - u40 + u45 =N= 1000;

e7..    eps*x7 - u39 + u44 =N= 1000;

e8..    eps*x8 - u40 + u46 =N= 1000;

e9..    eps*x9 + u43 =N= 1200;

e10..    eps*x10 + u45 =N= 1200;

e11..    eps*x11 + u44 =N= 1200;

e12..    eps*x12 + u46 =N= 1200;

e13..    eps*x13 - u51 + u54 =N= 20;

e14..    eps*x14 - u52 =N= 20;

e15..    eps*x15 + u52 - u53 =N= 20;

e16..    eps*x16 - u54 =N= 20;

e17..    eps*x17 + u41 =N= 3000;

e18..    eps*x18 + u42 =N= 3000;

e19..    eps*x19 - u51 + u52 =N= 20;

e20..    eps*x20 - u52 =N= 20;

e21..    eps*x21 - u53 + u54 =N= 20;

e22..    eps*x22 - u54 =N= 20;

e23..    eps*x23 - u47 + u48 =N= 300;

e24..    eps*x24 - u48 =N= 300;

e25..    eps*x25 - u49 + u50 =N= 300;

e26..    eps*x26 - u50 =N= 300;

e27..    eps*x27 - 900*u35 - 6*u43 + u47 - u51 =N= 0;

e28..    eps*x28 - 90*u35 + u51 =N= 0;

e29..    eps*x29 - 900*u36 - 6*u45 + u48 - u52 =N= 0;

e30..    eps*x30 - 90*u36 + u52 =N= 0;

e31..    eps*x31 - 600*u37 - 6*u44 + u49 - u53 =N= 0;

e32..    eps*x32 - 60*u37 + u53 =N= 0;

e33..    eps*x33 - 600*u38 - 6*u46 + u50 - u54 =N= 0;

e34..    eps*x34 - 60*u38 + u54 =N= 0;

e35..    900*x27 + 90*x28 =L= 8;

e36..    900*x29 + 90*x30 =L= 80000;

e37..    600*x31 + 60*x32 =L= 70000;

e38..    600*x33 + 60*x34 =L= 70000;

e39..    x5 + x7 =L= 1000;

e40..    x6 + x8 =L= 1000;

e41..    x1 + x3 - x17 =E= 130;

e42..    x2 + x4 - x18 =E= 190;

e43..  - x5 - x9 + 6*x27 =E= 0;

e44..  - x7 - x11 + 6*x31 =E= 0;

e45..  - x6 - x10 + 6*x29 =E= 0;

e46..  - x8 - x12 + 6*x33 =E= 0;

e47..    x1 + x23 - x27 =E= 5;

e48..    x2 - x23 + x24 - x29 =E= 0;

e49..    x3 + x25 - x31 =E= 2;

e50..    x4 - x25 + x26 - x33 =E= 0;

e51..    x13 + x19 + x27 - x28 =E= 6;

e52..    x14 - x15 - x19 + x20 + x29 - x30 =E= 0;

e53..    x15 + x21 + x31 - x32 =E= 4;

e54..  - x13 + x16 - x21 + x22 + x33 - x34 =E= 0;

Model m / e1.x1,e2.x2,e3.x3,e4.x4,e5.x5,e6.x6,e7.x7,e8.x8,e9.x9,e10.x10
         ,e11.x11,e12.x12,e13.x13,e14.x14,e15.x15,e16.x16,e17.x17,e18.x18
         ,e19.x19,e20.x20,e21.x21,e22.x22,e23.x23,e24.x24,e25.x25,e26.x26
         ,e27.x27,e28.x28,e29.x29,e30.x30,e31.x31,e32.x32,e33.x33,e34.x34
         ,e35.u35,e36.u36,e37.u37,e38.u38,e39.u39,e40.u40,e41.u41,e42.u42
         ,e43.u43,e44.u44,e45.u45,e46.u46,e47.u47,e48.u48,e49.u49,e50.u50
         ,e51.u51,e52.u52,e53.u53,e54.u54 /;

m.limrow=0; m.limcol=0;

* Regenerate this instance's polyhedral row information before solving.
File linlibPolyFile / 'poly.txt' /;
linlibPolyFile.pc = 2;
Scalar linlibPolyRow;
put linlibPolyFile;
for (linlibPolyRow = 35 to 54,
    put 'e' linlibPolyRow:0:0 /;
);
putclose linlibPolyFile '';

Solve m using MCP;
