***********************************************
* written by GAMS/JAMS at 11/08/26 17:18:41
* for more information use JAMS option "Dict"
***********************************************

Variables  x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16,x17,x18,x19
          ,x20,x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,x31,x32,x33,x34,x35,x36
          ,x37,x38,x39,x40,x41,x42,x43,x44,x45,x46,x47,x48,x49,x50,x51,x52,x53
          ,x54,x55,x56,x57,x58,x59,x60,x61,x62,x63,x64,x65,x66,x67,x68,x69,x70
          ,x71,x72,x73,x74,x75,x76,x77,x78,x79,x80,x81,x82,x83,u84,u85,u86,u87
          ,u88,u89,u90,u91,u92,u93,u94,u95,u96,u97,u98,u99,u100,u101,u102,u103;

Negative Variables  u95;

Positive Variables  x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16,x17
          ,x18,x19,x20,x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,x31,x33,x34,x35
          ,x36,x37,x38,x39,x40,x41,x42,x43,x44,x45,x46,x47,x48,x49,x50,x51,x52
          ,x53,x54,x55,x56,x57,x58,x59,x60,x61,x62,x63,x64,x65,x66,x67,x68,x69
          ,x70,x71,x72,x73,x74,x75,x76,x77,x78,x79,x80,x81,x82,x83;

Positive Variables  u84,u85,u86,u87,u88,u89,u90,u91,u92,u93,u94;

Equations  e1,e2,e3,e4,e5,e6,e7,e8,e9,e10,e11,e12,e13,e14,e15,e16,e17,e18,e19
          ,e20,e21,e22,e23,e24,e25,e26,e27,e28,e29,e30,e31,e32,e33,e34,e35,e36
          ,e37,e38,e39,e40,e41,e42,e43,e44,e45,e46,e47,e48,e49,e50,e51,e52,e53
          ,e54,e55,e56,e57,e58,e59,e60,e61,e62,e63,e64,e65,e66,e67,e68,e69,e70
          ,e71,e72,e73,e74,e75,e76,e77,e78,e79,e80,e81,e82,e83,e84,e85,e86,e87
          ,e88,e89,e90,e91,e92,e93,e94,e95,e96,e97,e98,e99,e100,e101,e102,e103;


e1..    eps*x1 =N= 0;

e2..    eps*x2 + u97 =N= -0.00072;

e3..    eps*x3 + u97 =N= 0;

e4..    eps*x4 + u98 =N= -0.00049;

e5..    eps*x5 + u98 =N= 0;

e6..    eps*x6 + u99 =N= -0.00033;

e7..    eps*x7 + u99 =N= 0;

e8..    eps*x8 + u100 =N= -0.00022;

e9..    eps*x9 + u100 =N= 0;

e10..    eps*x10 + u101 =N= -0.00015;

e11..    eps*x11 + u101 =N= 0;

e12..    eps*x12 + u102 =N= -0.0001;

e13..    eps*x13 + u102 =N= 0;

e14..    eps*x14 =N= 0;

e15..    eps*x15 =N= 0;

e16..    eps*x16 + u84 =N= 0;

e17..    eps*x17 + u85 =N= 0;

e18..    eps*x18 + u86 =N= 0;

e19..    eps*x19 + u87 =N= 0;

e20..    eps*x20 + u88 =N= 0;

e21..    eps*x21 + u89 =N= 0;

e22..    eps*x22 + u90 =N= 0;

e23..    eps*x23 + u91 =N= 0;

e24..    eps*x24 + u92 =N= 0;

e25..    eps*x25 + u93 =N= 0;

e26..    eps*x26 - u95 =N= 0;

e27..    eps*x27 - u94 =N= 0;

e28..    eps*x28 =N= 0;

e29..    eps*x29 =N= 0;

e30..    eps*x30 =N= 0;

e31..    eps*x31 =N= 0;

e32..    eps*x32 - 2800*u96 - 1.59091*u97 - 2.46212*u98 - 1.59091*u99
       - 2.46212*u100 - 1.59091*u101 - 2.46212*u102 - 20*u103 =N= 0;

e33..    eps*x33 =N= 0;

e34..    eps*x34 =N= 0;

e35..    eps*x35 =N= 0;

e36..    eps*x36 =N= 0;

e37..    eps*x37 =N= 0;

e38..    eps*x38 =N= 0;

e39..    eps*x39 =N= 0;

e40..    eps*x40 =N= 0;

e41..    eps*x41 =N= 0;

e42..    eps*x42 =N= 0;

e43..    eps*x43 =N= 0;

e44..    eps*x44 =N= 0;

e45..    eps*x45 =N= 0;

e46..    eps*x46 =N= 0;

e47..    eps*x47 =N= 0;

e48..    eps*x48 =N= 0;

e49..    eps*x49 =N= 0;

e50..    eps*x50 =N= 0;

e51..    eps*x51 =N= 0;

e52..    eps*x52 =N= 0;

e53..    eps*x53 =N= 0;

e54..    eps*x54 =N= 0;

e55..    eps*x55 =N= 0;

e56..    eps*x56 =N= 0;

e57..    eps*x57 =N= 0;

e58..    eps*x58 =N= 0;

e59..    eps*x59 =N= 0;

e60..    eps*x60 =N= 0;

e61..    eps*x61 =N= 0;

e62..    eps*x62 =N= 0;

e63..    eps*x63 =N= 0;

e64..    eps*x64 =N= 0;

e65..    eps*x65 =N= 0;

e66..    eps*x66 =N= 0;

e67..    eps*x67 =N= 0;

e68..    eps*x68 =N= 0;

e69..    eps*x69 =N= 0;

e70..    eps*x70 =N= 0;

e71..    eps*x71 =N= 0;

e72..    eps*x72 =N= 0;

e73..    eps*x73 =N= 0;

e74..    eps*x74 =N= 0;

e75..    eps*x75 =N= 0;

e76..    eps*x76 =N= 0;

e77..    eps*x77 =N= 0;

e78..    eps*x78 =N= 0;

e79..    eps*x79 =N= 0;

e80..    eps*x80 =N= 0;

e81..    eps*x81 =N= 0;

e82..    eps*x82 =N= 0;

e83..    eps*x83 =N= 0;

e84..  - x16 =G= 0;

e85..  - x17 =G= 0;

e86..  - x18 =G= 0;

e87..  - x19 =G= 0;

e88..  - x20 =G= 0;

e89..  - x21 =G= 0;

e90..  - x22 =G= 0;

e91..  - x23 =G= 0;

e92..  - x24 =G= 0;

e93..  - x25 =G= 0;

e94..    x27 =G= 0;

e95..    x26 =L= 0;

e96..    2800*x32 =E= 0;

e97..  - x2 - x3 + 1.59091*x32 =E= 0;

e98..  - x4 - x5 + 2.46212*x32 =E= 0;

e99..  - x6 - x7 + 1.59091*x32 =E= 0;

e100..  - x8 - x9 + 2.46212*x32 =E= 0;

e101..  - x10 - x11 + 1.59091*x32 =E= 0;

e102..  - x12 - x13 + 2.46212*x32 =E= 0;

e103..    20*x32 =E= 0;

* set non-default bounds
x1.up = 91;
x2.up = 298000;
x4.up = 298000;
x6.up = 298000;
x8.up = 298000;
x10.up = 298000;
x12.up = 298000;
x14.up = 32;
x32.fx = 83;

Model m / e1.x1,e2.x2,e3.x3,e4.x4,e5.x5,e6.x6,e7.x7,e8.x8,e9.x9,e10.x10
         ,e11.x11,e12.x12,e13.x13,e14.x14,e15.x15,e16.x16,e17.x17,e18.x18
         ,e19.x19,e20.x20,e21.x21,e22.x22,e23.x23,e24.x24,e25.x25,e26.x26
         ,e27.x27,e28.x28,e29.x29,e30.x30,e31.x31,e32.x32,e33.x33,e34.x34
         ,e35.x35,e36.x36,e37.x37,e38.x38,e39.x39,e40.x40,e41.x41,e42.x42
         ,e43.x43,e44.x44,e45.x45,e46.x46,e47.x47,e48.x48,e49.x49,e50.x50
         ,e51.x51,e52.x52,e53.x53,e54.x54,e55.x55,e56.x56,e57.x57,e58.x58
         ,e59.x59,e60.x60,e61.x61,e62.x62,e63.x63,e64.x64,e65.x65,e66.x66
         ,e67.x67,e68.x68,e69.x69,e70.x70,e71.x71,e72.x72,e73.x73,e74.x74
         ,e75.x75,e76.x76,e77.x77,e78.x78,e79.x79,e80.x80,e81.x81,e82.x82
         ,e83.x83,e84.u84,e85.u85,e86.u86,e87.u87,e88.u88,e89.u89,e90.u90
         ,e91.u91,e92.u92,e93.u93,e94.u94,e95.u95,e96.u96,e97.u97,e98.u98
         ,e99.u99,e100.u100,e101.u101,e102.u102,e103.u103 /;

m.limrow=0; m.limcol=0;

* Regenerate this instance's polyhedral row information before solving.
File linlibPolyFile / 'poly.txt' /;
linlibPolyFile.pc = 2;
Scalar linlibPolyRow;
put linlibPolyFile;
for (linlibPolyRow = 84 to 103,
    put 'e' linlibPolyRow:0:0 /;
);
putclose linlibPolyFile '';

Solve m using MCP;
