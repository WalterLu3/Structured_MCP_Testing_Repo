sets i players /1*300/;
sets j variables /1*50/;
set c constraints /1*40/;
alias (j,k);

option seed = 11;

positive variables x(i,j), p(j);
equations gradf(i,j), cons(i,c), invdem(j);

parameter M(i,j,k), B(i,c,j), q(i,j), r(i,c), a(j), pcap;
$ontext
$gdxin vidata.gdx
$loadIdx Q, B, c, r
$gdxin
$offtext
M(i,j,j) = 1;
q(i,j) = -i.ord;
* B(i,c,j) = 1$(c.ord = j.ord);
B(i,c,j) = uniform(0,1);
x.l(i,j) = uniform(0,100);
r(i,c) = sum(j, B(i,c,j)*x.l(i,j));
a(j) = uniform(0,0.1);
pcap = 0.5*smax(j, a(j)*sum(i, x.l(i,j)));
x.l(i,j) = 0;

gradf(i,j)..
  sum(k, M(i,j,k)*x(i,k)) + q(i,j) - p(j) =n= 0;

cons(i,c)..
  sum(j, B(i,c,j)*x(i,j)) =e= r(i,c) + 0.0*sum(j, p(j));

invdem(j)..
  p(j) =e= pcap - a(j)*sum(i, x(i,j));

model vi / gradf, cons, invdem /;

file fx /"%emp.info%"/;
put fx 'equilibrium'/;
put 'vi invdem p'/;
putclose fx 'vi gradf x cons';

* create polyhedral using gams embedded code
* This is a hack since we know exactly the cardinality of F in our VI and the number of linear constraint.

scalar
     ustart
     uend
;
ustart = card(j) * card(i) + 1;
uend =  card(j) * card(i) + card(i) * card(c);

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

solve vi using emp;
