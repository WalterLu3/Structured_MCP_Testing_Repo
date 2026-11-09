***********************************************
* written by GAMS/JAMS at 11/08/26 17:17:45
* for more information use JAMS option "Dict"
***********************************************

Variables  x1;

Positive Variables  x1;

Equations  e1;


e1..    eps*x1 =N= 0;

Model m / e1.x1 /;

m.limrow=0; m.limcol=0;

* This instance has no polyhedral rows.
$onEcho > poly.txt
$offEcho

Solve m using MCP;
