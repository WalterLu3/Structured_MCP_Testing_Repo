* file: parameters.gms

* purpose: setting parameters.

* algorithm: choose algoithms for solving
$if not setglobal algorithm $setglobal algorithm PATH

* data: setting the tree structure
$if not setglobal data $setglobal data tree3

* randomSeed: seed to generate random data as demand and
*             the weight of quadratic term
$if not setglobal randomSeed $setglobal randomSeed 1

* agentN: number of agents in the system
$if not setglobal agentN $setglobal agentN 2

* goodN: number of types of commodity in the system
$if not setglobal goodN $setglobal goodN 1

* dataType: (probably not needed)
* $if not setglobal dataType $setglobal dataType 1

* quad: the weight of the quadratic term in objectives
$if not setglobal quad $setglobal quad 10

* demandType: demandType (1,2 or 3) from the thesis
$if not setglobal demandType $setglobal demandType 1

* lambda: weight between expected value or CVaR.
*         0 means risk neutral
$if not setglobal lambda $setglobal lambda 0.3

* alpha: alpha of CVaR.
$if not setglobal alpha $setglobal alpha 0.74

* gamma_p: weight used to define the demand function of
*          type 2 and type 3 demands
$if not setglobal gamma_p $setglobal gamma_p 1e-2

* iterNum: iteration number for the PD algorithm
$if not setglobal iterationLimit $setglobal iterationLimit 100

* experimental parameters for line search
$if not setglobal decay1 $setglobal decay1 10
$if not setglobal decay2 $setglobal decay2 0
$if not setglobal decay3 $setglobal decay3 0

* experimental parameters for armijo type algorithm 
$if not setglobal worsen $setglobal worsen 9
$if not setglobal worst $setglobal worst 8
$if not setglobal better $setglobal better 1.1

* dual_prox: dual proximal perturbation
$if not setglobal dual_prox $setglobal dual_prox 0

* check solution against the original model
$if not setglobal checkSolution $setglobal checkSolution FALSE

* problem type ( normal: orignal SE (stochastic equilibrium)
*                social: social risk agent model )

$if not setglobal problemType $setglobal problemType normal

* proximalTerm: weight of the proximal term in the primal problem
$if not setglobal proximalTerm $setglobal proximalTerm 0

* to save the solution x q s p as gdx or not
$if not setglobal saveSolutionAsGdx $setglobal saveSolutionAsGdx FALSE