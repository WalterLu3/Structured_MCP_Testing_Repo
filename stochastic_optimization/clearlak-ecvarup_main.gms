$TITLE risk-averse test with artificial trees

************************************************
* Parameter file
************************************************

$if not setglobal experimentType $setglobal experimentType checkSame
$if not setglobal randomSeed $setglobal randomSeed 1
$if not setglobal nchildren $setglobal nchildren 3
$if not setglobal nstage $setglobal nstage 4
$if not setglobal iterationLimit $setglobal iterationLimit 10
$if not setglobal penalizeRisk $setglobal penalizeRisk 0
$if not setglobal penalizeConvex $setglobal penalizeConvex 0
$if not setglobal penalizePrimalKKT $setglobal penalizePrimalKKT 0

* ppterm controls the extra quadratic term in the primal
$if not setglobal ppterm $setglobal ppterm 0
* pterm controls the penalty for primal KKT violation
$if not setglobal pterm $setglobal pterm 0
$if not setglobal pert $setglobal pert 0

************************************************
* Model file
************************************************

$include clearlak-ecvarup_model.gms


************************************************
* Experiments
************************************************

$ifthen %experimentType% == checkSame

$include experiments/experiment_checkSame.gms

$elseif %experimentType% == checkPD

$include experiments/experiment_checkPD.gms

$elseif %experimentType% == alternativeLP

$include experiments/experiment_PD_alternativeLP.gms

$elseif %experimentType% == exactD

$include experiments/experiment_exact_D.gms

$elseif %experimentType% == optimalWithDStep

$include experiments/experiment_optimalWithDStep.gms

$elseif %experimentType% == optimalWithDStepAlternative

$include experiments/experiment_optimalWithDStepAlternative.gms

$elseif %experimentType% == optimalWithDStepNLP

$include experiments/experiment_optimalWithDStep_nlp.gms

$elseif %experimentType% == optimalWithDStepNLPStartWithEquil

$include experiments/experiment_optimalWithDStep_startWithEquil.gms

$elseif %experimentType% == EquOptimalWithDStepNLP

$include experiments/experiment_EquOptimalWithDStep_nlp.gms

$elseif %experimentType% == directSolutionFromRU

$include experiments/experiment_direct_solution_from_RU.gms

$elseif %experimentType% == findMultiplier

$include experiments/experiment_different_multiplier_on_different_y.gms

$elseif %experimentType% == PD-NLP-LCONS

$include experiments/experiment_PD_nlp_with_lcons.gms

$elseif %experimentType% == exactD-alternative

$include experiments/experiment_exact_D_alternative.gms

$elseif %experimentType% == PD-MCP-VI

$include experiments/experiment_PD_mcp_with_lcons_vi.gms

$elseif %experimentType% == PD-MPEC

$include experiments/experiment_PD_MPEC.gms

$elseif %experimentType% == PATHNLP

$include experiments/experiment_PATHNLP.gms

$elseif %experimentType% == MULTIPLE-AGENT

$include experiments/experiment_MULTIPLE_AGENT.gms

$elseif %experimentType% == checkPD-MPEC

$include experiments/experiment_checkPD_MPEC.gms 

$elseif %experimentType% == checkPD-MPEC-CONSTRAINT

$include experiments/experiment_checkPD_MPEC_Constraint.gms 

$elseif %experimentType% == checkPD-MPEC-Adjusted

$include experiments/experiment_checkPD_MPEC_adjustedWeight.gms

$elseif %experimentType% == P-alternative-D-alternative

$include experiments/experiment_P_alternative_D_alternative.gms

$elseif %experimentType% == PD-NLP-Sensitivity-Analysis

$include experiments/experiment_PD_nlp_sensitivity_analysis.gms

$elseif %experimentType% == PD-NLP-Sensitivity-Analysis-Square

$include experiments/experiment_PD_nlp_sensitivity_analysis_square.gms

$elseif %experimentType% == PD-NLP-Sensitivity-Analysis-Prox

$include experiments/experiment_PD_nlp_sensitivity_analysis_prox.gms

$elseif %experimentType% == PD-NLP-Sensitivity-Analysis-Algo

$include experiments/experiment_PD_nlp_sensitivity_analysis_algo.gms

** experiments for PD-PATH vs PATH
$elseif %experimentType% == Equilibrium

$include experiments/experiment_equilibrium.gms

$elseif %experimentType% == PD-PATH

$include experiments/experiment_PD_PATH.gms

$elseif %experimentType% == PD-PATH-LP

$include experiments/experiment_PD_PATH_LP.gms

$elseif %experimentType% == PD-PATH-NLP

$include experiments/experiment_PD_PATH_NLP.gms

$elseif %experimentType% == PD-Alternative-PATH

$include experiments/experiment_PD_alternative_PATH.gms

$elseif %experimentType% == RU

$include experiments/experiment_RU.gms

$elseif %experimentType% == RU-PATH

$include experiments/experiment_RU_PATH.gms

$elseif %experimentType% == RU-FOR-PATH

$include experiments/experiment_RU_for_PATH.gms


$endif