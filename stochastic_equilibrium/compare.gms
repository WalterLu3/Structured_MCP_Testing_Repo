set a, i, n;

$gdxin unittest_data/test_answer_1.gdx
$load a = a
$load i = i
$load n = n
parameter solutionX(a,i,n), solutionQ(a,i,n), solutionS(a,i,n), solutionP(i,n);
$load solutionX = solutionX
$load solutionQ = solutionQ
$load solutionS = solutionS
$load solutionP = solutionP
$gdxin

$gdxin checking_answer.gdx
parameter checkingX(a,i,n), checkingQ(a,i,n), checkingS(a,i,n), checkingP(i,n);
$load checkingX = checkingX
$load checkingQ = checkingQ
$load checkingS = checkingS 
$load checkingP = checkingP
$gdxin

scalar checkingResidual /0/;

loop(a,
    loop(i,
        loop(n,
            checkingResidual = checkingResidual + abs(solutionX(a,i,n) - checkingX(a,i,n));
            checkingResidual = checkingResidual + abs(solutionQ(a,i,n) - checkingQ(a,i,n));
            checkingResidual = checkingResidual + abs(solutionS(a,i,n) - checkingS(a,i,n));
        );
    );
);

loop(i,
    loop(n,
        checkingResidual = checkingResidual + abs(solutionP(i,n) - checkingP(i,n));
    );
);

display checkingResidual;