$if not set filename $abort 'File name was not specified.'

$ontext
"A structure-preserving pivotal method for affine variational inequalities, Y. Kim, 2008."
$offtext

sets i,j;
parameter Q(j,j), B(i,j), c(j), r(i);
$gdxin '%filename%.gdx'
$loadIdx Q, B, c, r
$gdxin


alias(j,k);

positive variables x(j);
equations gradf(j), cons(i);

gradf(k)..
  sum(j, Q(k,j)*x(j)) + c(k) =n= 0;

cons(i)..
  sum(j, B(i,j)*x(j)) =e= r(i);

model vi / gradf, cons /;

file fx /"%emp.info%"/;
putclose fx 'vi gradf x';

scalar
     ustart
     uend
;
ustart = card(k) + 1;
uend =  card(k) + card(i);

embeddedCode Python:

ustartPy = list(gams.get('ustart'))
uendPy = list(gams.get('uend'))

start = int(ustartPy[0])
end = int(uendPy[0])
# write poly.txt
with open("poly.txt","w") as f:
     for i in range(start,end+1):
          f.write("e{}\n".format(i))
endEmbeddedCode

* x.up(j) = 1e2;

$onecho > jams.opt
filename mcp_formulation.gms
subsolver path
terminate
$offecho

option emp = jams;
m.optfile = 1;

solve vi using emp;

scalar objval, objval_mcp;

objval = 0.5*sum(k, x.l(k)*sum(j, Q(k,j)*x.l(j))) + sum(k, c(k)*x.l(k));

file log /''/; put log;
log.nd = 6;
put
   '--- Objective Value (VI)   = ', objval /;
putclose log;

$exit

* following only works if Q is symmetric
equation defobj; variable obj;
defobj.. obj =e= 0.5*sum(k, x(k)*sum(j, Q(k,j)*x(j))) + sum(k, c(k)*x(k)); 

model qp / defobj, cons /;
solve qp using qcp min obj;
