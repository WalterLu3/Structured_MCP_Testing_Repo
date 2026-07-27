* file: main_tree.gms

* purpose: file for testing tree structure formulation
*          of reshop

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

$ifthen %demandType% == 1

$include FischerBurmeisterMacros/FBmerit_demandType_1.gms

$elseif %demandType% == 2

$include FischerBurmeisterMacros/FBmerit_demandType_2.gms

$elseif %demandType% == 3

$include FischerBurmeisterMacros/FBmerit_demandType_3.gms

$endif

*****************************************************
* Step 4. declare equilibrium model
*****************************************************

$include model_dispatch_tree.gms

*****************************************************
* Step 5. choose a solution algorithm
*****************************************************

$ifthen %algorithm% == PATH

$include algorithms_tree/algorithm_PATH.gms 

$elseif %algorithm% == PATH-RN

$include algorithms_tree/algorithm_PATH_RN.gms

$elseif %algorithm% == PD

$include algorithms_tree/algorithm_PD_dualEquil.gms

*$include algorithms/algorithm_PD_dualLP.gms

$elseif %algorithm% == PD-PATH

$include algorithms_tree/algorithm_PD_PATH.gms

*$elseif %algorithm% == PD-PATH-LP

*$include algorithms/algorithm_PD_dualLP.gms

$elseif %algorithm% == PD-CC-PATH

$include algorithms_tree/algorithm_PD_CC_PATH.gms

$endif




