$if not setglobal timeStages $setglobal timeStages 3
$if not setglobal childNum $setglobal childNum 5
$if not setglobal totalNodeNum $setglobal totalNodeNum 155
$if not setglobal newTreeName $setglobal newTreeName tempTree
* generate the tree structure

* node set
set n /n0*n%totalNodeNum%/;

alias(n,parent,child);

* child number of each node
scalar childNumber / %childNum% /;

* time stage (make the set really large to accomodate large trees)
* but we doe not necessarily use all of them
set t /t0*t10/;

* successor relation
set succ(n,n) ;

* timestage of each node
set nt(n,t);

* probability of each node
parameter prob(n);

* auxiliary set for loop
set iter/l1*l%childNum%/;


succ(parent,child) = no;

* temporary scalar and parameters
scalar tempTimeStage;
scalar tempNodeNum;
scalar tempTotalNum;
scalar stageOrder;
scalar nextStageStart;
parameter probIter(iter);
probIter(iter)  = 1;



* find nt : the time stage of each node
loop(parent,
* locate time stage of the point
    tempTimeStage = 2;
    tempNodeNum = 1;
    tempTotalNum = 0; 
    loop(t,
        if (ord(parent) = 1,
            tempTimeStage = 1;
            break;
        );
        tempNodeNum = tempNodeNum * childNumber;
        tempTotalNum = tempTotalNum + tempNodeNum;
        if (tempTotalNum >= ord(parent) - 1,
            break;
        );
        tempTimeStage = tempTimeStage + 1;
    );
    nt(parent,t)$(ord(t) = tempTimeStage) = yes;
);

* find succ : the successors of parent and child nodes 

loop(parent,
    tempTimeStage = sum(nt(parent,t),ord(t));
    tempNodeNum = 1;
    tempTotalNum = 0; 
*   locate the start of tempTimeStage (stored in tempTotalNum)
    while( tempTotalNum + tempNodeNum < ord(parent),
        tempTotalNum = tempTotalNum + tempNodeNum;
        tempNodeNum = tempNodeNum * childNumber;
    );

    stageOrder = ord(parent) - tempTotalNum ;
    nextStageStart = tempTotalNum + childNumber**(tempTimeStage - 1);
* fill in the successors info and probability info

embeddedcode Python:
import gams.transfer as gt
import numpy as np
import random

def random_positive_probabilities(n, decimals=2, rng=None):
    if n < 1:
        raise ValueError("n must be >= 1")
    S = 10 ** decimals
    if n > S:
        raise ValueError(f"Cannot guarantee >0 with {n} parts at {decimals} decimals")

    rng = rng or random

    stars_bars = [1] * (S - n) + [0] * (n - 1)
    rng.shuffle(stars_bars)

    parts, count = [], 0
    for x in stars_bars:
        if x == 1:
            count += 1
        else:
            parts.append(count)
            count = 0
    parts.append(count)

    return [(p + 1) / S for p in parts]

m = gt.Container(gams.db)
childNumber = int(m.data["childNumber"].toDense() + 0.5)
#gams.printLog(random_positive_probabilities(childNumber))
m.data['probIter'].setRecords(np.array(random_positive_probabilities(childNumber)))
m.write(gams.db, ["probIter"])
endembeddedcode probIter


    loop(iter,
        succ(parent,child)$(ord(child) < nextStageStart + (childNumber * (stageOrder - 1) ) + ord(iter) + 0.5 and ord(child) > nextStageStart + (childNumber * (stageOrder - 1) ) + ord(iter) - 0.5) = yes;
        prob(child)$(ord(child) < nextStageStart + (childNumber * (stageOrder - 1) ) + ord(iter) + 0.5 and ord(child) > nextStageStart + (childNumber * (stageOrder - 1) ) + ord(iter) - 0.5) = probIter(iter);
    );
);

prob('n0') = 1;



display succ;
display prob;
display nt;
display t;




* set n /n0*n5/;
* set t /t0*t1/;

* set succ(n,n) /n0.n1, n0.n2, n0.n3, n0.n4, n0.n5/;

* set nt(n,t);

* nt(n,t) = no;

* nt('n0','t0') = yes;
* nt('n1','t1') = yes;
* nt('n2','t1') = yes;
* nt('n3','t1') = yes;
* nt('n4','t1') = yes;
* nt('n5','t1') = yes;

* parameter prob(n) /n0 1, n1 0.1, n2 0.2, n3 0.3, n4 0.1, n5 0.3/;

* display prob;
* display succ;
* display nt;

execute_unload '%newTreeName%.gdx', n, t, succ, nt, prob;