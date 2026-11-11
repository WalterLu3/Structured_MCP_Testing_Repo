***********************************************
* written by GAMS/JAMS at 11/08/26 17:22:55
* for more information use JAMS option "Dict"
***********************************************

Variables  x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16,x17,x18,x19
          ,x20,x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,x31,x32,x33,x34,x35,x36;

Positive Variables  x1,x2,x3,x4,x5,x6,x7,x8,x9,x10,x11,x12,x13,x14,x15,x16,x17
          ,x18,x19,x20,x21,x22,x23,x24,x25,x26,x27,x28,x29,x30,x31,x32,x33,x34
          ,x35,x36;

Equations  e1,e2,e3,e4,e5,e6,e7,e8,e9,e10,e11,e12,e13,e14,e15,e16,e17,e18,e19
          ,e20,e21,e22,e23,e24,e25,e26,e27,e28,e29,e30,e31,e32,e33,e34,e35,e36;


e1..    eps*x1 =N= 0;

e2..    eps*x2 =N= 0;

e3..    eps*x3 =N= 0;

e4..    eps*x4 =N= 0;

e5..    eps*x5 =N= 0;

e6..    eps*x6 =N= 0;

e7..    eps*x7 =N= 0;

e8..    eps*x8 =N= 0;

e9..    eps*x9 =N= 0;

e10..    eps*x10 =N= 0;

e11..    eps*x11 =N= 0;

e12..    eps*x12 =N= 0;

e13..    eps*x13 =N= 0;

e14..    eps*x14 =N= 0;

e15..    eps*x15 =N= 0;

e16..    eps*x16 =N= 0;

e17..    eps*x17 =N= 0;

e18..    eps*x18 =N= 0;

e19..    eps*x19 =N= 0;

e20..    eps*x20 =N= 0;

e21..    eps*x21 =N= 0;

e22..    eps*x22 =N= 0;

e23..    eps*x23 =N= 0;

e24..    eps*x24 =N= 0;

e25..    eps*x25 =N= 0;

e26..    eps*x26 =N= 0;

e27..    eps*x27 =N= 0;

e28..    eps*x28 =N= 0;

e29..    eps*x29 =N= 0;

e30..    eps*x30 =N= 0;

e31..    eps*x31 =N= 0;

e32..    eps*x32 =N= 0;

e33..    eps*x33 =N= 0;

e34..    eps*x34 =N= 0;

e35..    eps*x35 =N= 0;

e36..    eps*x36 =N= 0;

Model m / e1.x1,e2.x2,e3.x3,e4.x4,e5.x5,e6.x6,e7.x7,e8.x8,e9.x9,e10.x10
         ,e11.x11,e12.x12,e13.x13,e14.x14,e15.x15,e16.x16,e17.x17,e18.x18
         ,e19.x19,e20.x20,e21.x21,e22.x22,e23.x23,e24.x24,e25.x25,e26.x26
         ,e27.x27,e28.x28,e29.x29,e30.x30,e31.x31,e32.x32,e33.x33,e34.x34
         ,e35.x35,e36.x36 /;

m.limrow=0; m.limcol=0;

* This instance has no polyhedral rows.
$onEcho > poly.txt
$offEcho

Solve m using MCP;
