***********************************************
* written by GAMS/JAMS at 11/08/26 17:17:45
* for more information use JAMS option "Dict"
***********************************************

Variables  x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16,x17,x18,x19
          ,x20,x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,x31,x32,u33,u34,u35,u36
          ,u37,u38,u39,u40,u41,u42,u43,u44,u45,u46,u47,u48,u49,u50,u51,u52,u53
          ,u54,u55,u56,u57,u58,u59;

Negative Variables  u33,u34,u35,u36,u37,u38,u39,u40,u41,u42,u43,u44,u45,u46
          ,u47,u48,u49,u50,u51;

Positive Variables  x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16,x17
          ,x18,x19,x20,x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,x31,x32;

Equations  e1,e2,e3,e4,e5,e6,e7,e8,e9,e10,e11,e12,e13,e14,e15,e16,e17,e18,e19
          ,e20,e21,e22,e23,e24,e25,e26,e27,e28,e29,e30,e31,e32,e33,e34,e35,e36
          ,e37,e38,e39,e40,e41,e42,e43,e44,e45,e46,e47,e48,e49,e50,e51,e52,e53
          ,e54,e55,e56,e57,e58,e59;


e1..    eps*x1 - u33 - 0.301*u48 + u52 + 1.06*u53 =N= 0;

e2..    eps*x2 + u34 - u52 =N= 0.4;

e3..    eps*x3 + u46 - u52 =N= 0;

e4..    eps*x4 - u50 - u53 =N= 0;

e5..    eps*x5 - u35 - 0.301*u49 + u54 + 1.06*u55 =N= 0;

e6..    eps*x6 - u36 - 0.313*u49 + u54 + 1.06*u55 =N= 0;

e7..    eps*x7 - u37 - 0.313*u49 + u54 + 0.96*u55 =N= 0;

e8..    eps*x8 - u38 - 0.326*u49 + u54 + 0.86*u55 =N= 0;

e9..    eps*x9 + u35 - 2.364*u45 =N= 0;

e10..    eps*x10 + u36 - 2.386*u45 =N= 0;

e11..    eps*x11 + u37 - 2.408*u45 =N= 0;

e12..    eps*x12 + u38 - 2.429*u45 =N= 0;

e13..    eps*x13 - 1.4*u34 - u54 =N= 0.32;

e14..    eps*x14 + u47 - u54 =N= 0;

e15..    eps*x15 - u51 - u55 =N= 0;

e16..    eps*x16 - u39 - 0.109*u46 + u56 + 0.43*u57 =N= 0;

e17..    eps*x17 + u40 - u56 =N= 0.6;

e18..    eps*x18 + u48 - u56 =N= 0;

e19..    eps*x19 + u45 - u56 =N= 0;

e20..    eps*x20 - u50 - u57 =N= 0;

e21..    eps*x21 - u41 - 0.109*u47 + 0.43*u58 - u59 =N= 0;

e22..    eps*x22 - u42 - 0.108*u47 + 0.43*u58 - u59 =N= 0;

e23..    eps*x23 - u43 - 0.108*u47 + 0.39*u58 - u59 =N= 0;

e24..    eps*x24 - u44 - 0.107*u47 + 0.37*u58 - u59 =N= 0;

e25..    eps*x25 + u41 - 2.191*u45 =N= 0;

e26..    eps*x26 + u42 - 2.219*u45 =N= 0;

e27..    eps*x27 + u43 - 2.249*u45 =N= 0;

e28..    eps*x28 + u44 - 2.279*u45 =N= 0;

e29..    eps*x29 - 1.4*u40 + u59 =N= 0.48;

e30..    eps*x30 + u49 - u59 =N= 0;

e31..    eps*x31 - u51 - u58 =N= 0;

e32..    eps*x32 - u59 =N= -10;

e33..    x1 =L= 80;

e34..  - x2 + 1.4*x13 =L= 0;

e35..    x5 - x9 =L= 80;

e36..    x6 - x10 =L= 0;

e37..    x7 - x11 =L= 0;

e38..    x8 - x12 =L= 0;

e39..    x16 =L= 500;

e40..  - x17 + 1.4*x29 =L= 0;

e41..    x21 - x25 =L= 500;

e42..    x22 - x26 =L= 0;

e43..    x23 - x27 =L= 0;

e44..    x24 - x28 =L= 0;

e45..    2.364*x9 + 2.386*x10 + 2.408*x11 + 2.429*x12 - x19 + 2.191*x25
       + 2.219*x26 + 2.249*x27 + 2.279*x28 =L= 0;

e46..  - x3 + 0.109*x16 =L= 0;

e47..  - x14 + 0.109*x21 + 0.108*x22 + 0.108*x23 + 0.107*x24 =L= 0;

e48..    0.301*x1 - x18 =L= 0;

e49..    0.301*x5 + 0.313*x6 + 0.313*x7 + 0.326*x8 - x30 =L= 0;

e50..    x4 + x20 =L= 310;

e51..    x15 + x31 =L= 300;

e52..  - x1 + x2 + x3 =E= 0;

e53..  - 1.06*x1 + x4 =E= 0;

e54..  - x5 - x6 - x7 - x8 + x13 + x14 =E= 0;

e55..  - 1.06*x5 - 1.06*x6 - 0.96*x7 - 0.86*x8 + x15 =E= 0;

e56..  - x16 + x17 + x18 + x19 =E= 0;

e57..  - 0.43*x16 + x20 =E= 0;

e58..  - 0.43*x21 - 0.43*x22 - 0.39*x23 - 0.37*x24 + x31 =E= 0;

e59..    x21 + x22 + x23 + x24 - x29 + x30 + x32 =E= 44;

Model m / e1.x1,e2.x2,e3.x3,e4.x4,e5.x5,e6.x6,e7.x7,e8.x8,e9.x9,e10.x10
         ,e11.x11,e12.x12,e13.x13,e14.x14,e15.x15,e16.x16,e17.x17,e18.x18
         ,e19.x19,e20.x20,e21.x21,e22.x22,e23.x23,e24.x24,e25.x25,e26.x26
         ,e27.x27,e28.x28,e29.x29,e30.x30,e31.x31,e32.x32,e33.u33,e34.u34
         ,e35.u35,e36.u36,e37.u37,e38.u38,e39.u39,e40.u40,e41.u41,e42.u42
         ,e43.u43,e44.u44,e45.u45,e46.u46,e47.u47,e48.u48,e49.u49,e50.u50
         ,e51.u51,e52.u52,e53.u53,e54.u54,e55.u55,e56.u56,e57.u57,e58.u58
         ,e59.u59 /;

m.limrow=0; m.limcol=0;

* Regenerate this instance's polyhedral row information before solving.
File linlibPolyFile / 'poly.txt' /;
linlibPolyFile.pc = 2;
Scalar linlibPolyRow;
put linlibPolyFile;
for (linlibPolyRow = 33 to 59,
    put 'e' linlibPolyRow:0:0 /;
);
putclose linlibPolyFile '';

Solve m using MCP;
