***********************************************
* written by GAMS/JAMS at 11/08/26 17:22:47
* for more information use JAMS option "Dict"
***********************************************

Variables  x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16,x17,x18,x19
          ,x20,x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,x31,x32,x33,u34,u35,u36
          ,u37,u38,u39,u40,u41,u42,u43,u44,u45,u46,u47,u48,u49,u50,u51,u52,u53
          ,u54,u55,u56,u57,u58,u59,u60,u61,u62;

Negative Variables  u54,u55,u56,u57,u58,u59,u60,u61,u62;

Positive Variables  x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16,x17
          ,x18,x19,x20,x21,x22,x24,x25,x26,x27,x28,x29,x30,x31,x32,x33;

Positive Variables  u34,u35,u36,u37,u38,u39,u40,u41,u42,u43,u44,u45,u46,u47
          ,u48,u49,u50,u51,u52,u53;

Equations  e1,e2,e3,e4,e5,e6,e7,e8,e9,e10,e11,e12,e13,e14,e15,e16,e17,e18,e19
          ,e20,e21,e22,e23,e24,e25,e26,e27,e28,e29,e30,e31,e32,e33,e34,e35,e36
          ,e37,e38,e39,e40,e41,e42,e43,e44,e45,e46,e47,e48,e49,e50,e51,e52,e53
          ,e54,e55,e56,e57,e58,e59,e60,e61,e62;


e1..    eps*x1 - 3*u34 - u36 - u45 - u54 - u62 =N= -0.24;

e2..    eps*x2 + 3*u34 + u36 - u45 - u56 - u62 =N= -0.27;

e3..    eps*x3 - 7*u34 + 1.5*u36 - u45 - u57 - u62 =N= -0.25;

e4..    eps*x4 - 9*u34 - 66*u36 - u45 - u62 =N= -0.29;

e5..    eps*x5 - 10*u34 + 2*u36 - u45 - u61 - u62 =N= -0.23;

e6..    eps*x6 - 11*u35 - 0.5*u37 - u46 - u54 - u62 =N= -0.15;

e7..    eps*x7 - 3*u35 + 3.5*u37 - u46 - u56 - u62 =N= -0.18;

e8..    eps*x8 - 15*u35 + 2*u37 - u46 - u57 - u62 =N= -0.16;

e9..    eps*x9 - 20*u35 - 3.5*u37 - u46 - u61 - u62 =N= -0.14;

e10..    eps*x10 - 0.5*u38 - u47 - u54 - u62 =N= 0.78;

e11..    eps*x11 + 2.5*u38 - u47 - u55 - u62 =N= -0.15;

e12..    eps*x12 + 0.5*u38 - u47 - u62 =N= 0.25;

e13..    eps*x13 + 3.5*u38 - u47 - u62 =N= -0.1;

e14..    eps*x14 - 3.5*u38 - u47 - u56 - u62 =N= 0.75;

e15..    eps*x15 - u48 - u54 - u62 =N= 0.18;

e16..    eps*x16 - 3*u39 - u48 - u55 - u62 =N= -0.75;

e17..    eps*x17 - 0.5*u39 - u48 - u58 - u62 =N= -0.55;

e18..    eps*x18 - 3*u40 - u49 - u55 - u62 =N= -1.05;

e19..    eps*x19 - 1.5*u40 - u49 - u62 =N= -0.15;

e20..    eps*x20 - 0.5*u40 - u49 - u58 - u62 =N= 0.15;

e21..    eps*x21 - 3*u41 - u50 - u55 - u62 =N= -0.35;

e22..    eps*x22 - 0.5*u41 - u50 - u58 - u62 =N= -0.15;

e23..    eps*x23 - u58 - u62 =N= -0.11;

e24..    eps*x24 - u42 - u51 - u58 - u62 =N= 4.35;

e25..    eps*x25 - 8*u42 - u51 - u62 =N= -0.15;

e26..    eps*x26 - 12*u42 - u51 - u62 =N= -0.1;

e27..    eps*x27 - 12*u43 - u52 - u62 =N= -0.13;

e28..    eps*x28 - 8*u43 - u52 - u59 - u62 =N= -0.09;

e29..    eps*x29 - 5*u43 - u52 - u60 - u62 =N= -0.05;

e30..    eps*x30 - 7*u44 - u53 - u59 - u62 =N= -0.24;

e31..    eps*x31 - 3*u44 - u53 - u60 =N= -0.2;

e32..    eps*x32 - u39 =N= 0;

e33..    eps*x33 - u56 =N= 0;

e34..    3*x1 - 3*x2 + 7*x3 + 9*x4 + 10*x5 =G= 0;

e35..    11*x6 + 3*x7 + 15*x8 + 20*x9 =G= 0;

e36..    x1 - x2 - 1.5*x3 + 66*x4 - 2*x5 =G= 0;

e37..    0.5*x6 - 3.5*x7 - 2*x8 + 3.5*x9 =G= 0;

e38..    0.5*x10 - 2.5*x11 - 0.5*x12 - 3.5*x13 + 3.5*x14 =G= 0;

e39..    3*x16 + 0.5*x17 + x32 =G= 0;

e40..    3*x18 + 1.5*x19 + 0.5*x20 =G= 0;

e41..    3*x21 + 0.5*x22 =G= 0;

e42..    x24 + 8*x25 + 12*x26 =G= 0;

e43..    12*x27 + 8*x28 + 5*x29 =G= 0;

e44..    7*x30 + 3*x31 =G= 0;

e45..    x1 + x2 + x3 + x4 + x5 =G= 40000;

e46..    x6 + x7 + x8 + x9 =G= 18500;

e47..    x10 + x11 + x12 + x13 + x14 =G= 15000;

e48..    x15 + x16 + x17 =G= 1200;

e49..    x18 + x19 + x20 =G= 1500;

e50..    x21 + x22 =G= 1000;

e51..    x24 + x25 + x26 =G= 80000;

e52..    x27 + x28 + x29 =G= 18000;

e53..    x30 + x31 =G= 60000;

e54..    x1 + x6 + x10 + x15 =L= 87500;

e55..    x11 + x16 + x18 + x21 =L= 50000;

e56..    x2 + x7 + x14 + x33 =L= 66000;

e57..    x3 + x8 =L= 50000;

e58..    x17 + x20 + x22 + x23 + x24 =L= 82500;

e59..    x28 + x30 =L= 55000;

e60..    x29 + x31 =L= 66000;

e61..    x5 + x9 =L= 6300;

e62..    x1 + x2 + x3 + x4 + x5 + x6 + x7 + x8 + x9 + x10 + x11 + x12 + x13
       + x14 + x15 + x16 + x17 + x18 + x19 + x20 + x21 + x22 + x23 + x24 + x25
       + x26 + x27 + x28 + x29 + x30 =L= 415000;

* set non-default bounds
x4.up = 70000;
x12.up = 50000;
x13.up = 20000;
x23.lo = 15000;
x25.up = 50000;
x26.up = 75000;
x27.up = 3300;

* set non-default levels
x23.l = 15000;

Model m / e1.x1,e2.x2,e3.x3,e4.x4,e5.x5,e6.x6,e7.x7,e8.x8,e9.x9,e10.x10
         ,e11.x11,e12.x12,e13.x13,e14.x14,e15.x15,e16.x16,e17.x17,e18.x18
         ,e19.x19,e20.x20,e21.x21,e22.x22,e23.x23,e24.x24,e25.x25,e26.x26
         ,e27.x27,e28.x28,e29.x29,e30.x30,e31.x31,e32.x32,e33.x33,e34.u34
         ,e35.u35,e36.u36,e37.u37,e38.u38,e39.u39,e40.u40,e41.u41,e42.u42
         ,e43.u43,e44.u44,e45.u45,e46.u46,e47.u47,e48.u48,e49.u49,e50.u50
         ,e51.u51,e52.u52,e53.u53,e54.u54,e55.u55,e56.u56,e57.u57,e58.u58
         ,e59.u59,e60.u60,e61.u61,e62.u62 /;

m.limrow=0; m.limcol=0;

* Regenerate this instance's polyhedral row information before solving.
File linlibPolyFile / 'poly.txt' /;
linlibPolyFile.pc = 2;
Scalar linlibPolyRow;
put linlibPolyFile;
for (linlibPolyRow = 34 to 62,
    put 'e' linlibPolyRow:0:0 /;
);
putclose linlibPolyFile '';

Solve m using MCP;
