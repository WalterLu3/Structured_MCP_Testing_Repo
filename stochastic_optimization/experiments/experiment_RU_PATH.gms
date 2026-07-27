option reslim=1200;
option lp=pathnlp;

solve mincost using emp minimizing EC;

scalar t_used;
t_used = timeElapsed;

display t_used;