***********************************************
* written by GAMS/JAMS at 11/08/26 17:21:28
* for more information use JAMS option "Dict"
***********************************************

Variables  x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16,x17,x18,x19
          ,x20,x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,x31,x32,x33,x34,x35,x36
          ,x37,x38,x39,x40,x41,x42,x43,x44,x45,x46,u47,u48,u49,u50,u51,u52,u53
          ,u54,u55,u56,u57,u58;

Positive Variables  x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16,x17
          ,x18,x19,x20,x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,x31,x32,x33,x34
          ,x35,x36,x37,x38,x39,x40,x41,x42,x43,x44,x45,x46;

Equations  e1,e2,e3,e4,e5,e6,e7,e8,e9,e10,e11,e12,e13,e14,e15,e16,e17,e18,e19
          ,e20,e21,e22,e23,e24,e25,e26,e27,e28,e29,e30,e31,e32,e33,e34,e35,e36
          ,e37,e38,e39,e40,e41,e42,e43,e44,e45,e46,e47,e48,e49,e50,e51,e52,e53
          ,e54,e55,e56,e57,e58;


e1..    eps*x1 + u47 - u49 =N= -10000000;

e2..    eps*x2 - u47 + u49 =N= 0;

e3..    eps*x3 + u48 - u50 =N= -10000000;

e4..    eps*x4 + u48 - u50 =N= -0.00416667;

e5..    eps*x5 - u48 + u50 =N= 0;

e6..    eps*x6 - u48 + u50 =N= -0.0024975;

e7..    eps*x7 + u49 - u51 =N= -10000000;

e8..    eps*x8 - u49 + u51 =N= 0;

e9..    eps*x9 + u50 - u52 =N= -10000000;

e10..    eps*x10 + u50 - u52 =N= -0.00416667;

e11..    eps*x11 - u50 + u52 =N= 0;

e12..    eps*x12 - u50 + u52 =N= -0.0024975;

e13..    eps*x13 + u49 - u50 =N= -0.00124863;

e14..    eps*x14 - u49 + u50 =N= -0.00124863;

e15..    eps*x15 + u51 - u53 =N= -10000000;

e16..    eps*x16 - u51 + u53 =N= 0;

e17..    eps*x17 + u52 - u54 =N= -10000000;

e18..    eps*x18 + u52 - u54 =N= -0.00416667;

e19..    eps*x19 - u52 + u54 =N= 0;

e20..    eps*x20 - u52 + u54 =N= -0.0024975;

e21..    eps*x21 + u51 - u52 =N= -0.00124863;

e22..    eps*x22 - u51 + u52 =N= -0.00124863;

e23..    eps*x23 + u53 - u55 =N= -10000000;

e24..    eps*x24 - u53 + u55 =N= 0;

e25..    eps*x25 + u54 - u56 =N= -10000000;

e26..    eps*x26 + u54 - u56 =N= -0.00416667;

e27..    eps*x27 - u54 + u56 =N= 0;

e28..    eps*x28 - u54 + u56 =N= -0.0024975;

e29..    eps*x29 + u53 - u54 =N= -0.00124863;

e30..    eps*x30 - u53 + u54 =N= -0.00124863;

e31..    eps*x31 + u55 - u57 =N= -10000000;

e32..    eps*x32 - u55 + u57 =N= 0;

e33..    eps*x33 + u56 - u58 =N= -10000000;

e34..    eps*x34 + u56 - u58 =N= -0.00416667;

e35..    eps*x35 - u56 + u58 =N= 0;

e36..    eps*x36 - u56 + u58 =N= -0.0024975;

e37..    eps*x37 + u55 - u56 =N= -10000000;

e38..    eps*x38 - u55 + u56 =N= -10000000;

e39..    eps*x39 + u57 =N= -10000000;

e40..    eps*x40 - u57 =N= 0;

e41..    eps*x41 + u58 =N= -10000000;

e42..    eps*x42 + u58 =N= -0.00416667;

e43..    eps*x43 - u58 =N= 0;

e44..    eps*x44 - u58 =N= -0.0024975;

e45..    eps*x45 + u57 - u58 =N= -10000000;

e46..    eps*x46 - u57 + u58 =N= -10000000;

e47..  - x1 + x2 =E= 1000100;

e48..  - x3 - x4 + x5 + x6 =E= 200;

e49..    x1 - x2 - x7 + x8 - x13 + x14 =E= 200;

e50..    x3 + x4 - x5 - x6 - x9 - x10 + x11 + x12 + x13 - x14 =E= 400;

e51..    x7 - x8 - x15 + x16 - x21 + x22 =E= 300;

e52..    x9 + x10 - x11 - x12 - x17 - x18 + x19 + x20 + x21 - x22 =E= 600;

e53..    x15 - x16 - x23 + x24 - x29 + x30 =E= 400;

e54..    x17 + x18 - x19 - x20 - x25 - x26 + x27 + x28 + x29 - x30 =E= 800;

e55..    x23 - x24 - x31 + x32 - x37 + x38 =E= 500;

e56..    x25 + x26 - x27 - x28 - x33 - x34 + x35 + x36 + x37 - x38 =E= 1000;

e57..    x31 - x32 - x39 + x40 - x45 + x46 =E= 600;

e58..    x33 + x34 - x35 - x36 - x41 - x42 + x43 + x44 + x45 - x46 =E= 1200;

* set non-default bounds
x4.up = 12000;
x5.up = 7980;
x10.up = 12000;
x11.up = 7980;
x13.up = 1080;
x14.up = 1080;
x18.up = 12000;
x19.up = 7980;
x21.up = 1080;
x22.up = 1080;
x26.up = 12000;
x27.up = 7980;
x29.up = 1080;
x30.up = 1080;
x34.up = 12000;
x35.up = 7980;
x37.up = 1080;
x38.up = 1080;
x42.up = 12000;
x43.up = 7980;
x45.up = 1080;
x46.up = 1080;

Model m / e1.x1,e2.x2,e3.x3,e4.x4,e5.x5,e6.x6,e7.x7,e8.x8,e9.x9,e10.x10
         ,e11.x11,e12.x12,e13.x13,e14.x14,e15.x15,e16.x16,e17.x17,e18.x18
         ,e19.x19,e20.x20,e21.x21,e22.x22,e23.x23,e24.x24,e25.x25,e26.x26
         ,e27.x27,e28.x28,e29.x29,e30.x30,e31.x31,e32.x32,e33.x33,e34.x34
         ,e35.x35,e36.x36,e37.x37,e38.x38,e39.x39,e40.x40,e41.x41,e42.x42
         ,e43.x43,e44.x44,e45.x45,e46.x46,e47.u47,e48.u48,e49.u49,e50.u50
         ,e51.u51,e52.u52,e53.u53,e54.u54,e55.u55,e56.u56,e57.u57,e58.u58 /;

m.limrow=0; m.limcol=0;

* Regenerate this instance's polyhedral row information before solving.
File linlibPolyFile / 'poly.txt' /;
linlibPolyFile.pc = 2;
Scalar linlibPolyRow;
put linlibPolyFile;
for (linlibPolyRow = 47 to 58,
    put 'e' linlibPolyRow:0:0 /;
);
putclose linlibPolyFile '';

Solve m using MCP;
