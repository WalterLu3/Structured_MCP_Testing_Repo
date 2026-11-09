***********************************************
* written by GAMS/JAMS at 11/08/26 17:22:57
* for more information use JAMS option "Dict"
***********************************************

Variables  x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16,x17,x18,x19
          ,x20,x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,x31,x32,x33,x34,x35,x36
          ,x37,x38,x39,x40,x41,x42,x43,x44,x45,x46,x47,x48,u49,u50,u51,u52,u53
          ,u54,u55,u56,u57,u58,u59,u60,u61,u62,u63,u64,u65,u66,u67,u68,u69,u70
          ,u71,u72,u73,u74,u75,u76,u77,u78,u79,u80,u81,u82,u83,u84,u85,u86,u87
          ,u88,u89,u90,u91,u92,u93,u94,u95,u96;

Negative Variables  u49,u50,u51,u52,u53,u54,u55,u56,u57,u58,u59,u60,u61,u62
          ,u63,u64,u65,u66,u67,u68,u69,u70,u71,u72,u73,u74,u75,u76;

Positive Variables  x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16,x17
          ,x18,x19,x20,x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,x31,x32,x33,x34
          ,x35,x36,x37,x38,x39,x40,x41,x42,x43,x44,x45,x46,x47,x48;

Equations  e1,e2,e3,e4,e5,e6,e7,e8,e9,e10,e11,e12,e13,e14,e15,e16,e17,e18,e19
          ,e20,e21,e22,e23,e24,e25,e26,e27,e28,e29,e30,e31,e32,e33,e34,e35,e36
          ,e37,e38,e39,e40,e41,e42,e43,e44,e45,e46,e47,e48,e49,e50,e51,e52,e53
          ,e54,e55,e56,e57,e58,e59,e60,e61,e62,e63,e64,e65,e66,e67,e68,e69,e70
          ,e71,e72,e73,e74,e75,e76,e77,e78,e79,e80,e81,e82,e83,e84,e85,e86,e87
          ,e88,e89,e90,e91,e92,e93,e94,e95,e96;


e1..    eps*x1 - 3*u49 + u78 =N= 0;

e2..    eps*x2 - 3*u49 + u79 =N= 0;

e3..    eps*x3 - 3*u49 + u80 =N= 0;

e4..    eps*x4 - u77 - 1.1*u81 =N= 1;

e5..    eps*x5 - 0.4*u54 - 0.6*u55 + u77 - u82 =N= 0;

e6..    eps*x6 + u50 - u78 + u83 =N= 0;

e7..    eps*x7 + u51 - u79 + u84 =N= 0;

e8..    eps*x8 + u52 - u80 + u85 =N= 0;

e9..    eps*x9 - u50 + u53 =N= 0;

e10..    eps*x10 - u51 + u54 =N= 0;

e11..    eps*x11 - u52 + u55 =N= 0;

e12..    eps*x12 - 3*u53 + u83 =N= 0;

e13..    eps*x13 - 3*u53 + u84 =N= 0;

e14..    eps*x14 - 3*u53 + u85 =N= 0;

e15..    eps*x15 + u81 - u82 - 1.1*u86 =N= 0;

e16..    eps*x16 - 0.4*u60 - 0.6*u61 + u82 - u87 =N= 0;

e17..    eps*x17 + u56 - u83 + u88 =N= 0;

e18..    eps*x18 + u57 - u84 + u89 =N= 0;

e19..    eps*x19 + u58 - u85 + u90 =N= 0;

e20..    eps*x20 - u56 + u59 =N= 0;

e21..    eps*x21 - u57 + u60 =N= 0;

e22..    eps*x22 - u58 + u61 =N= 0;

e23..    eps*x23 - 3*u59 + u88 =N= 0;

e24..    eps*x24 - 3*u59 + u89 =N= 0;

e25..    eps*x25 - 3*u59 + u90 =N= 0;

e26..    eps*x26 + u86 - u87 - 1.1*u91 =N= 0;

e27..    eps*x27 - 0.4*u66 - 0.6*u67 + u87 - u92 =N= 0;

e28..    eps*x28 + u62 - u88 + u93 =N= 0;

e29..    eps*x29 + u63 - u89 + u94 =N= 0;

e30..    eps*x30 + u64 - u90 + u95 =N= 0;

e31..    eps*x31 - u62 + u65 =N= 0;

e32..    eps*x32 - u63 + u66 =N= 0;

e33..    eps*x33 - u64 + u67 =N= 0;

e34..    eps*x34 - 3*u65 + u93 =N= 0;

e35..    eps*x35 - 3*u65 + u94 =N= 0;

e36..    eps*x36 - 3*u65 + u95 =N= 0;

e37..    eps*x37 + u91 - u92 - 1.1*u96 =N= 0;

e38..    eps*x38 - 0.4*u72 - 0.6*u73 + u92 =N= 0;

e39..    eps*x39 + u68 - u93 =N= 0;

e40..    eps*x40 + u69 - u94 =N= 0;

e41..    eps*x41 + u70 - u95 =N= 0;

e42..    eps*x42 - u68 + u71 =N= 0;

e43..    eps*x43 - u69 + u72 =N= 0;

e44..    eps*x44 - u70 + u73 =N= 0;

e45..    eps*x45 - 3*u71 + 0.7*u74 =N= 0;

e46..    eps*x46 - 3*u71 - 0.3*u74 + u75 =N= 0;

e47..    eps*x47 - 3*u71 - 0.3*u74 + u76 =N= 0;

e48..    eps*x48 - 0.4*u75 - 0.6*u76 + u96 =N= 0;

e49..    3*x1 + 3*x2 + 3*x3 =L= 300;

e50..  - x6 + x9 =L= 0;

e51..  - x7 + x10 =L= 0;

e52..  - x8 + x11 =L= 0;

e53..  - x9 + 3*x12 + 3*x13 + 3*x14 =L= 300;

e54..    0.4*x5 - x10 =L= 0;

e55..    0.6*x5 - x11 =L= 0;

e56..  - x17 + x20 =L= 0;

e57..  - x18 + x21 =L= 0;

e58..  - x19 + x22 =L= 0;

e59..  - x20 + 3*x23 + 3*x24 + 3*x25 =L= 300;

e60..    0.4*x16 - x21 =L= 0;

e61..    0.6*x16 - x22 =L= 0;

e62..  - x28 + x31 =L= 0;

e63..  - x29 + x32 =L= 0;

e64..  - x30 + x33 =L= 0;

e65..  - x31 + 3*x34 + 3*x35 + 3*x36 =L= 300;

e66..    0.4*x27 - x32 =L= 0;

e67..    0.6*x27 - x33 =L= 0;

e68..  - x39 + x42 =L= 0;

e69..  - x40 + x43 =L= 0;

e70..  - x41 + x44 =L= 0;

e71..  - x42 + 3*x45 + 3*x46 + 3*x47 =L= 300;

e72..    0.4*x38 - x43 =L= 0;

e73..    0.6*x38 - x44 =L= 0;

e74..  - 0.7*x45 + 0.3*x46 + 0.3*x47 =L= 0;

e75..  - x46 + 0.4*x48 =L= 0;

e76..  - x47 + 0.6*x48 =L= 0;

e77..    x4 - x5 =E= 0;

e78..  - x1 + x6 =E= 0;

e79..  - x2 + x7 =E= 0;

e80..  - x3 + x8 =E= 0;

e81..    1.1*x4 - x15 =E= 0;

e82..    x5 + x15 - x16 =E= 0;

e83..  - x6 - x12 + x17 =E= 0;

e84..  - x7 - x13 + x18 =E= 0;

e85..  - x8 - x14 + x19 =E= 0;

e86..    1.1*x15 - x26 =E= 0;

e87..    x16 + x26 - x27 =E= 0;

e88..  - x17 - x23 + x28 =E= 0;

e89..  - x18 - x24 + x29 =E= 0;

e90..  - x19 - x25 + x30 =E= 0;

e91..    1.1*x26 - x37 =E= 0;

e92..    x27 + x37 - x38 =E= 0;

e93..  - x28 - x34 + x39 =E= 0;

e94..  - x29 - x35 + x40 =E= 0;

e95..  - x30 - x36 + x41 =E= 0;

e96..    1.1*x37 - x48 =E= 0;

Model m / e1.x1,e2.x2,e3.x3,e4.x4,e5.x5,e6.x6,e7.x7,e8.x8,e9.x9,e10.x10
         ,e11.x11,e12.x12,e13.x13,e14.x14,e15.x15,e16.x16,e17.x17,e18.x18
         ,e19.x19,e20.x20,e21.x21,e22.x22,e23.x23,e24.x24,e25.x25,e26.x26
         ,e27.x27,e28.x28,e29.x29,e30.x30,e31.x31,e32.x32,e33.x33,e34.x34
         ,e35.x35,e36.x36,e37.x37,e38.x38,e39.x39,e40.x40,e41.x41,e42.x42
         ,e43.x43,e44.x44,e45.x45,e46.x46,e47.x47,e48.x48,e49.u49,e50.u50
         ,e51.u51,e52.u52,e53.u53,e54.u54,e55.u55,e56.u56,e57.u57,e58.u58
         ,e59.u59,e60.u60,e61.u61,e62.u62,e63.u63,e64.u64,e65.u65,e66.u66
         ,e67.u67,e68.u68,e69.u69,e70.u70,e71.u71,e72.u72,e73.u73,e74.u74
         ,e75.u75,e76.u76,e77.u77,e78.u78,e79.u79,e80.u80,e81.u81,e82.u82
         ,e83.u83,e84.u84,e85.u85,e86.u86,e87.u87,e88.u88,e89.u89,e90.u90
         ,e91.u91,e92.u92,e93.u93,e94.u94,e95.u95,e96.u96 /;

m.limrow=0; m.limcol=0;

* Regenerate this instance's polyhedral row information before solving.
File linlibPolyFile / 'poly.txt' /;
linlibPolyFile.pc = 2;
Scalar linlibPolyRow;
put linlibPolyFile;
for (linlibPolyRow = 49 to 96,
    put 'e' linlibPolyRow:0:0 /;
);
putclose linlibPolyFile '';

Solve m using MCP;
