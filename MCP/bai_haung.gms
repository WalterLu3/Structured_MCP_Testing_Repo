
* This comes from a paper by bai and haung.

$if not setglobal dimension $setglobal dimension 200
* $setglobal ntilde 200

set t / 1 * %dimension% /;
alias(t,tt);

positive variables x(t,tt);
equations f(t,tt);

f(t,tt)..
   - x(t - 1,tt) + 4*x(t,tt) - 1*x(t+1,tt) - 1*x(t,tt+1) - 1*x(t,tt-1)
   + mod(card(t)*(ord(t)-1) + ord(tt) + 1, 2) 
   - mod(card(t)*(ord(t)-1) + ord(tt), 2) 
  =g= 0;

model foo /f.x/;

x.l(t,tt) = 40;

solve foo using mcp;

