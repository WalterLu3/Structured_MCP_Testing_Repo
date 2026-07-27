* file: model_dispatch.gms

* purpose: generate and load data for problem 


*****************************************************
* Step 1. transform some parameters into scalar
*****************************************************
option decimals=8;
scalar randomSeed /%randomSeed%/
	   quad /%quad%/
	   lambda /%lambda%/
	   alpha /%alpha%/
	   iterationLimit /%iterationLimit%/
	   gamma_p /%gamma_p%/
	   dual_prox /%dual_prox%/
	   tail
	   proximalTerm /%proximalTerm%/
;
tail = 1 - alpha;

execseed = randomSeed;

*****************************************************
* Step 2. create agents and good sets
*****************************************************
set a 	agents  /a1*a%agentN%/,
	i	goods  /i1*i%goodN%/;

alias(a, b, agent);
alias(i,j,good);

set ia(good,agent)	does agent produce good /#i.#a/
;

alias(ia,jb);


scalar agentNumber;
agentNumber = card(a);

*****************************************************
* Step 3. load scenario tree
*****************************************************
$gdxin %data%.gdx
set n;
$load n = n
set t;
$load t = t
set succ(n,n);
$load succ = succ
set nt(n,t);
$load nt = nt
parameter prob;
$load prob = prob
$gdxin

alias(succ, succI, succII);
alias(n, node, parent, child, grandchild, ggrandchild);
alias(n, gggrandchild, grandchild2, grandchild3);

* explanations:
* n: nodes
* t: stage
* succ(n1,n2): yes if n1 is the parent of n2
* nt(n,t): which stage does node n belong to
* prob(n): probability to transfer from n's
*          parent node to n

scalar maxTimeStage /0/;

set sn(n) nonroot nodes
	root(n) root nodes
	leafn(n) leaf nodes
	parentn(n, parent) parent node is the parent of n
;

loop(nt(n,t)$[ord(t) > 1],
	sn(n) = yes;
);
loop(nt(n,t)$[ord(t) eq 1],
	root(n) = yes;
);

loop(n,
	if (maxTimeStage < sum(nt(n,t), ord(t)),
		maxTimeStage = sum(nt(n,t), ord(t));
	);

);

loop(nt(n,t)$[ord(t) eq maxTimeStage],
	leafn(n) = yes;
);
loop(succ(parent,child),
	parentn(child, parent) = yes;
);

* construct scenario tree probability

Parameter
	rprob(n) scenario tree probability
;

rprob('n0') = 1;

loop(n$sn(n),
	loop(parentn(n, parent),
		rprob(n) = rprob(parent)*prob(n);
	);
);

* some other parameters used in the model
Parameter
* referece parameter used in type 2 market constraint
	p_ref(i,n) /#i.#n 0/
;

*****************************************************
* Step 4. Using random seeds to generate data
*****************************************************

* Random data include random demand and random 
* quadratic weight of the cost function

parameter
	D(i,n)      demand
	c1(a,i,n)   quadratic term for cost function for q 
	c2(a,i,n)   linear term for cost function for q 
	Cap(a,i,n)  storage upper bound
	cx1(a,i,n)  quadratic term for cost function for x
	cx2(a,i,n)  linear term for cost function for x
	cx3(a,i,n)  constant term for cost function for x 
	cq1(a,i,n)  quadratic term for cost function for q
	cq2(a,i,n)  linear term for cost function for q 
	cq3(a,i,n)  constant term for cost function for q 
	cs1(a,i,n)  quadratic term for cost function for s
	cs2(a,i,n)  linear term for cost function for s
	cs3(a,i,n)  constant term for cost function for s
;

* question: isn't c1 the same as cq1 and c2 the same as cq2?

loop(n,
	loop(i,
		D(i,n)$sn(n) = agentNumber*uniform(20,50)
	);
);

c1(a,i,n)$[ia(i,a) and sn(n)] = 0;
loop(a,
	loop(n$sn(n),
		c2(a,i,n)$[ia(i,a)] = uniform(10,20);
	);
);

loop(a,
	loop(n$sn(n),
		Cap(a,i,n)$[ia(i,a)] = uniform(40,75);
	);
);

cx1(a,i,n) = quad*uniform(0.9,1);
cx2(a,i,n) = 0;
cx3(a,i,n) = 0;
cq1(a,i,n) = quad*uniform(0.9,1);
cq2(a,i,n) = 0;
cq3(a,i,n) = 0;
cs1(a,i,n) = quad*uniform(0.9,1); 
cs2(a,i,n) = 0;
cs3(a,i,n) = 0;

*****************************************************
* Step 5. some paremeter setting
*****************************************************

* ain and in are not used anywhere... why?
set ain(a,i,n) 
	in(i,n);

ain(a,i,n) = no;
in(i,n) = no;
ain(a,i,n)$[ia(i,a) and sn(n)] = yes;
in(i,n)$sn(n) = yes;

Parameter 
	tau(a)	demand scale	/#a	1.0
				/
	xStart(a,i) start value
;

Scalar xup upper bound of x /100/,
	   xlo lower bound of x /20/
;

* set the initial x level value

xStart(a,i)$[ia(i,a)] = 50;

*****************************************************
* Step 6. Shared data (probably used for record)
*****************************************************
* define control sets for solving backward recursive LP subproblem
set subn(n)           for selecting a single node
	subchild(n)
	suba(a)           for selecting a single agent
;
subn('n0') = yes;
subchild('n1') = yes;
suba('a1') = yes;
alias(n,n_s);
alias(a,a_s);
alias(a,aaa);
alias(n,nnn);

alias (n, gggrandchild);
alias (child, child2);

alias(t,rt);
set 
	revt(t,rt)        for performing loop from the end time
;
revt(t,t+[card(t)-2*ord(t)+1]) = yes;
* In this case, only t0.t3 t1.t2 t2.t1 t3.t0 are yes.
* If we loop over this set of indices and extract the
* second index, we will get a backward loop of 
* t3 t2 t1 t0;

scalar 
	totalSolverTime /0/
	totalSolveTime /0/
	totalresUsd /0/
	starttime /0/
	elapsetime /0/
	modelStatus /0/
	solverStatus /0/
	majorIter /0/
	final_res /0/
	numNonopt /0/
	etSolve /0/
	etSolver /0/
	resUsd /0/
;

*****************************************************
* Step 7. Some extra parameters used in the models
*****************************************************

parameter 
	yl(a,n)         this is for creating primal equilibrium model where probabilities are fixed
	costOfChild(a,n)  this is for storing the child node cost in the objective of backward dual LP problems
;

scalar
	lpNormalizer    store the sum of absolute objective value for objective normalization in LP
	temp            some buffer
	iZero           for checking zero objectives
;