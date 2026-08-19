* file: main.gms

* purpose: the gms file containing the main structure
*          of the programming flow

*****************************************************
* Step 1. read in needed parameters
*****************************************************

$include parameters.gms

*****************************************************
* Step 2. data generation
*****************************************************

$include data_dispatch.gms

*****************************************************
* Step 3. some extra macros needed that are not 
*         related to model itself. 
*         Ex. Fischer Burmeister.
*****************************************************

* As the three demand types have different model,
* the way to calculate their FB residuals are different

$ifthen %problemType% == normal

$ifthen %demandType% == 1

$include FischerBurmeisterMacros/FBmerit_demandType_1.gms

$elseif %demandType% == 2

$include FischerBurmeisterMacros/FBmerit_demandType_2.gms

$elseif %demandType% == 3

$include FischerBurmeisterMacros/FBmerit_demandType_3.gms

$endif

$elseif %problemType% == social

$ifthen %demandType% == 1

$include FischerBurmeisterMacros/FBmerit_demandType_1_social.gms

$elseif %demandType% == 2
* not yet implemented
*$include FischerBurmeisterMacros/FBmerit_demandType_2_social.gms

$elseif %demandType% == 3

*not yet implemented
*$include FischerBurmeisterMacros/FBmerit_demandType_3_social.gms

$endif

$elseif %problemType% == mixed

$ifthen %demandType% == 1

$include FischerBurmeisterMacros/FBmerit_demandType_1.gms

$elseif %demandType% == 2

$include FischerBurmeisterMacros/FBmerit_demandType_2.gms

$elseif %demandType% == 3

$include FischerBurmeisterMacros/FBmerit_demandType_3.gms

$endif

$endif

*****************************************************
* Step 4. declare equilibrium model
*****************************************************

$include model_dispatch.gms

$include model_dispatch_social_risk_agent.gms

*****************************************************
* Step 5. choose a solution algorithm for normal model
*****************************************************

$ifthen %problemType% == normal

$ifthen %algorithm% == PATH

$include algorithms/algorithm_PATH.gms 

$elseif %algorithm% == PATH-RN

$include algorithms/algorithm_PATH_RN.gms

$elseif %algorithm% == PD

$include algorithms/algorithm_PD.gms

$elseif %algorithm% == PD-PATH

$include algorithms/algorithm_PD_PATH.gms

$elseif %algorithm% == BACKWARD

$include algorithms/algorithm_backward.gms

*$elseif %algorithm% == PD-PATH-LP

*$include algorithms/algorithm_PD_dualLP.gms

$elseif %algorithm% == PD-CC-PATH

$include algorithms/algorithm_PD_CC_PATH.gms

$elseif %algorithm% == CC-PATH

$include algorithms/algorithm_CC_PATH.gms

$elseif %algorithm% == PD-TrustRegion-PATH

$include algorithms/algorithm_PD_TrustRegion_PATH.gms

*$elseif %algorithm% == CC-PATH-T-BETTER
*
*$include algorithms/algorithm_CC_PATH_T_BETTER.gms
*
*$elseif %algorithm% == CC-PATH-T-BETTER-DIFF
*
*$include algorithms/algorithm_CC_PATH_T_BETTER_DIFF.gms
*
*$elseif %algorithm% == CC-PATH-ARMIJO
*
*$include algorithms/algorithm_CC_PATH_ARMIJO.gms
*
*$elseif %algorithm% == CC-PATH-ARMIJO-DIFF
*
*$include algorithms/algorithm_CC_PATH_ARMIJO_DIFF.gms
*
*$elseif %algorithm% == CC-PATH-ARMIJO-ACCURATE
*
*$include algorithms/algorithm_CC_PATH_ARMIJO_ACCURATE.gms

$elseif %algorithm% == PD-One-PATH

$include algorithms/algorithm_PD_1_PATH.gms

$elseif %algorithm% == PD-LineSearch-PATH

$include algorithms/algorithm_PD_LineSearh_PATH.gms

* 0.5 0.5 line search. If residual decrease, accept, else drop.
$elseif %algorithm% == PD-LineSearch-PATH-Residual

$include algorithms/algorithm_PD_LineSearh_PATH_Residual.gms

* armijo on all variables.
$elseif %algorithm% == PD-LineSearch-PATH-Armijo

$include algorithms/algorithm_PD_LineSearh_PATH_Armijo.gms

$elseif %algorithm% == PD-LineSearch-PATH-3Weights

$include algorithms/algorithm_PD_LineSearh_PATH_3Weights.gms

$elseif %algorithm% == dynamic

$include algorithms/algorithm_PATH_dynamic.gms

* $elseif %algorithm% == PD-VISUAL

* $include algorithms/algorithm_PD_VISUAL.gms

* $elseif %algorithm% == PD-PERT

* $include algorithms/algorithm_PD_PERT.gms

$endif

*****************************************************
* Step 5.1: save solution as gdx and check it aginst
*****************************************************

$ifthen %saveSolutionAsGdx% == TRUE

$include saveSolution.gms

$endif

*****************************************************
* Step 5.2: check solution against the original model
*****************************************************

$ifthen %checkSolution% == TRUE

$include checkSolution.gms

$endif


*****************************************************************
* Step 6. choose a solution algorithm for social risk agent model
*****************************************************************

$elseif %problemType% == social

$ifthen %algorithm% == PATH

$include algorithms_social_risk_agent/algorithm_PATH.gms 

$elseif %algorithm% == PATH-RN

$include algorithms_social_risk_agent/algorithm_PATH_RN.gms

$elseif %algorithm% == PD

$include algorithms_social_risk_agent/algorithm_PD.gms

$elseif %algorithm% == PD-PATH

$include algorithms_social_risk_agent/algorithm_PD_PATH.gms

$elseif %algorithm% == PD-CC-PATH

$include algorithms_social_risk_agent/algorithm_PD_CC_PATH.gms

$endif

*****************************************************************
* Step 7. choose a solution algorithm for mixed model
*****************************************************************

$elseif %problemType% == mixed

$ifthen %algorithm% == PD-CC-SOCIAL-PATH

$include algorithms_mixed/algorithm_PD_CC_SOCIAL_PATH.gms

$elseif %algorithm% == PD-CC-SOCIAL-PD-CC-PATH

$include algorithms_mixed/algorithm_PD_CC_SOCIAL_PD_CC_PATH.gms

$endif

$endif


