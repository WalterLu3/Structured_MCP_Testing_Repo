***********************************************
* written by GAMS/JAMS at 11/08/26 17:20:22
* for more information use JAMS option "Dict"
***********************************************

Variables  x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16,x17,x18,x19
          ,x20,x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,x31,x32,x33,x34,x35,x36
          ,x37,x38,x39,x40,u41,u42,u43,u44,u45,u46,u47,u48,u49,u50,u51,u52,u53
          ,u54,u55,u56,u57,u58,u59,u60,u61,u62,u63;

Negative Variables  u41,u42,u43,u44,u45,u46,u47,u48,u49,u50,u51,u52,u53,u54
          ,u55,u56,u57,u58,u59,u60,u61,u62,u63;

Positive Variables  x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16,x17
          ,x18,x19,x20,x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,x31,x32,x33,x34
          ,x35,x36,x37,x38,x39,x40;

Equations  e1,e2,e3,e4,e5,e6,e7,e8,e9,e10,e11,e12,e13,e14,e15,e16,e17,e18,e19
          ,e20,e21,e22,e23,e24,e25,e26,e27,e28,e29,e30,e31,e32,e33,e34,e35,e36
          ,e37,e38,e39,e40,e41,e42,e43,e44,e45,e46,e47,e48,e49,e50,e51,e52,e53
          ,e54,e55,e56,e57,e58,e59,e60,e61,e62,e63;


e1..    eps*x1 + u41 - u42 + 1669*u61 =N= -5612;

e2..    eps*x2 + u41 - u42 + 1669*u62 =N= -5051;

e3..    eps*x3 + u41 - u42 + 1669*u63 =N= -5526;

e4..    eps*x4 + u41 - u42 =N= -6033;

e5..    eps*x5 + u43 - u44 + 2191*u61 =N= -7452;

e6..    eps*x6 + u43 - u44 + 2191*u62 =N= -6757;

e7..    eps*x7 + u43 - u44 + 2191*u63 =N= -7466;

e8..    eps*x8 + u43 - u44 =N= -8161;

e9..    eps*x9 + u45 - u46 + 1553*u61 =N= -6594;

e10..    eps*x10 + u45 - u46 + 1553*u62 =N= -7189;

e11..    eps*x11 + u45 - u46 + 1553*u63 =N= -6842;

e12..    eps*x12 + u45 - u46 =N= -7304;

e13..    eps*x13 + u47 - u48 + 1829*u61 =N= -6370;

e14..    eps*x14 + u47 - u48 + 1829*u62 =N= -5781;

e15..    eps*x15 + u47 - u48 + 1829*u63 =N= -6232;

e16..    eps*x16 + u47 - u48 =N= -6794;

e17..    eps*x17 + u49 - u50 + 1772*u61 =N= -6413;

e18..    eps*x18 + u49 - u50 + 1772*u62 =N= -5779;

e19..    eps*x19 + u49 - u50 + 1772*u63 =N= -6233;

e20..    eps*x20 + u49 - u50 =N= -6616;

e21..    eps*x21 + u51 - u52 + 1665*u61 =N= -5892;

e22..    eps*x22 + u51 - u52 + 1665*u62 =N= -5313;

e23..    eps*x23 + u51 - u52 + 1665*u63 =N= -5838;

e24..    eps*x24 + u51 - u52 =N= -6086;

e25..    eps*x25 + u53 - u54 + 2220*u61 =N= -7628;

e26..    eps*x26 + u53 - u54 + 2220*u62 =N= -6989;

e27..    eps*x27 + u53 - u54 + 2220*u63 =N= -7578;

e28..    eps*x28 + u53 - u54 =N= -8029;

e29..    eps*x29 + u55 - u56 + 1634*u61 =N= -5638;

e30..    eps*x30 + u55 - u56 + 1634*u62 =N= -5163;

e31..    eps*x31 + u55 - u56 + 1634*u63 =N= -5577;

e32..    eps*x32 + u55 - u56 =N= -5986;

e33..    eps*x33 + u57 - u58 + 2211*u61 =N= -7509;

e34..    eps*x34 + u57 - u58 + 2211*u62 =N= -6895;

e35..    eps*x35 + u57 - u58 + 2211*u63 =N= -7461;

e36..    eps*x36 + u57 - u58 =N= -7951;

e37..    eps*x37 + u59 - u60 + 2142*u61 =N= -7383;

e38..    eps*x38 + u59 - u60 + 2142*u62 =N= -6779;

e39..    eps*x39 + u59 - u60 + 2142*u63 =N= -7373;

e40..    eps*x40 + u59 - u60 =N= -8059;

e41..  - x1 - x2 - x3 - x4 =L= -1;

e42..    x1 + x2 + x3 + x4 =L= 1;

e43..  - x5 - x6 - x7 - x8 =L= -1;

e44..    x5 + x6 + x7 + x8 =L= 1;

e45..  - x9 - x10 - x11 - x12 =L= -1;

e46..    x9 + x10 + x11 + x12 =L= 1;

e47..  - x13 - x14 - x15 - x16 =L= -1;

e48..    x13 + x14 + x15 + x16 =L= 1;

e49..  - x17 - x18 - x19 - x20 =L= -1;

e50..    x17 + x18 + x19 + x20 =L= 1;

e51..  - x21 - x22 - x23 - x24 =L= -1;

e52..    x21 + x22 + x23 + x24 =L= 1;

e53..  - x25 - x26 - x27 - x28 =L= -1;

e54..    x25 + x26 + x27 + x28 =L= 1;

e55..  - x29 - x30 - x31 - x32 =L= -1;

e56..    x29 + x30 + x31 + x32 =L= 1;

e57..  - x33 - x34 - x35 - x36 =L= -1;

e58..    x33 + x34 + x35 + x36 =L= 1;

e59..  - x37 - x38 - x39 - x40 =L= -1;

e60..    x37 + x38 + x39 + x40 =L= 1;

e61..  - 1669*x1 - 2191*x5 - 1553*x9 - 1829*x13 - 1772*x17 - 1665*x21
       - 2220*x25 - 1634*x29 - 2211*x33 - 2142*x37 =L= -2684;

e62..  - 1669*x2 - 2191*x6 - 1553*x10 - 1829*x14 - 1772*x18 - 1665*x22
       - 2220*x26 - 1634*x30 - 2211*x34 - 2142*x38 =L= -3215;

e63..  - 1669*x3 - 2191*x7 - 1553*x11 - 1829*x15 - 1772*x19 - 1665*x23
       - 2220*x27 - 1634*x31 - 2211*x35 - 2142*x39 =L= -1547;

* set non-default bounds
x1.up = 1;
x2.up = 1;
x3.up = 1;
x4.up = 1;
x5.up = 1;
x6.up = 1;
x7.up = 1;
x8.up = 1;
x9.up = 1;
x10.up = 1;
x11.up = 1;
x12.up = 1;
x13.up = 1;
x14.up = 1;
x15.up = 1;
x16.up = 1;
x17.up = 1;
x18.up = 1;
x19.up = 1;
x20.up = 1;
x21.up = 1;
x22.up = 1;
x23.up = 1;
x24.up = 1;
x25.up = 1;
x26.up = 1;
x27.up = 1;
x28.up = 1;
x29.up = 1;
x30.up = 1;
x31.up = 1;
x32.up = 1;
x33.up = 1;
x34.up = 1;
x35.up = 1;
x36.up = 1;
x37.up = 1;
x38.up = 1;
x39.up = 1;
x40.up = 1;

Model m / e1.x1,e2.x2,e3.x3,e4.x4,e5.x5,e6.x6,e7.x7,e8.x8,e9.x9,e10.x10
         ,e11.x11,e12.x12,e13.x13,e14.x14,e15.x15,e16.x16,e17.x17,e18.x18
         ,e19.x19,e20.x20,e21.x21,e22.x22,e23.x23,e24.x24,e25.x25,e26.x26
         ,e27.x27,e28.x28,e29.x29,e30.x30,e31.x31,e32.x32,e33.x33,e34.x34
         ,e35.x35,e36.x36,e37.x37,e38.x38,e39.x39,e40.x40,e41.u41,e42.u42
         ,e43.u43,e44.u44,e45.u45,e46.u46,e47.u47,e48.u48,e49.u49,e50.u50
         ,e51.u51,e52.u52,e53.u53,e54.u54,e55.u55,e56.u56,e57.u57,e58.u58
         ,e59.u59,e60.u60,e61.u61,e62.u62,e63.u63 /;

m.limrow=0; m.limcol=0;

* Regenerate this instance's polyhedral row information before solving.
File linlibPolyFile / 'poly.txt' /;
linlibPolyFile.pc = 2;
Scalar linlibPolyRow;
put linlibPolyFile;
for (linlibPolyRow = 41 to 63,
    put 'e' linlibPolyRow:0:0 /;
);
putclose linlibPolyFile '';

Solve m using MCP;
