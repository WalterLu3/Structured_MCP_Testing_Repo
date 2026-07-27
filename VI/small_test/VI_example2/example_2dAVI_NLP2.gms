Set      i /1*3/;
Variable x(i);



Equations F(i), h1, h2, h3, h4, h5;

F(i)..   (5*x('1')*x('1')  + 5)$sameas(i,'1')
         + (-x('2')*x('2') + 2)$sameas(i,'2')
         + (-x('1')*x('3') + 5)$sameas(i,'3')
         =n= 0;

h1..     x('1') + x('2') -1 =l= 0;
h2..     x('1') + x('2') +1 =g= 0;
h3..     x('1') - x('2') +1 =g= 0;
h4..     x('1') - x('2') -1 =l= 0;
h5..     x('3') + 2 * x('1') - 5 * x('2') =l= 2;


Model linVI / F, h1, h2, h3, h4, h5/;

File annotations /'%emp.info%'/;
put annotations;
putclose 'vi F x h1 h2 h3 h4 h5';

*write out the MCP reformulation of the GNEP optimization problem
$onEcho > jams.opt
filename mcp.gms
$offEcho

option emp = jams;

linVI.optfile=1;

solve linVI using emp;