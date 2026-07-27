$if not setglobal dimension $setglobal dimension 25

sets
    I / 1 * %dimension% /,
    J / 1 * %dimension% /,
    K / 1 * %dimension% /;

scalar csum;
parameter c(I,J,K);
execseed = 525;
c(I,J,K) = uniform(0,2);
csum = sum {(I,J,K), c(I,J,K)};

variables x(I,J,K), z;

equations obj, norm;

obj..   z =e= sum {(I,J,K), power(x(I,J,K)-c(I,J,K),2)};
norm..  csum * 0.4 =e= sum {(I,J,K), x(I,J,K)};

model super / obj, norm /;
option iterlim = 50000, reslim = 10800;

x.up(I,J,K) = .85;
scalars
    objVal,
    varCount,
    basCount    '# of basic vars',
    sbCount     '# of superbasic vars',
    nbCount     '# of nonbasic vars';

$if %system.filesys% == UNIX  $set console /dev/tty
$if %system.filesys% == DOS $set console con
$if %system.filesys% == MS95  $set console con
$if %system.filesys% == MSNT  $set console con
$if %system.filesys% == UNIX $set console /dev/tty

$if "%console%." == "." abort "filesys not recognized";

* file log / '%console%' /;
file log / 'super2.out.txt' /;
put log;

* MCP formulation
variable lambda         'Langragier to norm constraint';

equation delx(I,J,K)      'derivative of Lagrangian wrt x';

delx(I,J,K)..     2 * (x(I,J,K)-c(I,J,K)) + lambda =l= 0;

model superMCP / delx.x, norm.lambda /;

x.m(I,J,K) = 0;
x.l(I,J,K) = 0;

solve superMCP using MCP;

objVal   = sum {(I,J,K), power(x.l(I,J,K)-c(I,J,K),2)};
varCount = card(I) * card(J) * card(K) + 1;
nbCount  = sum {(I,J,K)$(x.m(I,J,K) ne 0), 1} + 1$(lambda.m ne 0);
basCount = varCount - nbCount;
sbCount  = 0;

put 'MCP results (PATH):'/;
put '   objVal : ', objVal:16:8/;
put ' varCount : ', varCount:16:8/;
put ' basCount : ', basCount:16:8/;
put '  nbCount : ', nbCount:16:8/;
put '  sbCount : ', sbCount:16:8/;
put /;

