This folder stores the stochastic dispatch experiment.

1. main.gms: the main file to run.
2. parameters.gms: the file containing all parameters.
3. data_dispatch.gms: the file generate and load data for problem 
4. model_dispatch.gms: the file containing the equilibrium models
5. algorithms/ : a repo that contains all algorithms that operates on equilibrium models
6. FischerBurmeisterMacros/ : a repo that contains the evaluation of FB residual for all tree types of demand
7. generate_tree.py helps generate random tree example, where we can specify the time stages and number of children nodes for a node.

Example: run
```
gams main --data=tree3 --randomSeed=1 --quad=1 --demandType=1 --lambda=0.5 --algorithm=PATH-RN
```

The above will run an example with:
1. tree stucture stored in tree3
2. all the random data are generated with seed = 1
3. quadratic term with a base of 1 times a random number
4. demand type (1) is the first one
5. alpha for the CVaR is 0.5
6. algorithm PATH-RN  (options: PATH, PATH-RN, PD, PD-PATH, PD-CC-PATH, etc. See other algorithm options in main.gms)
7. problemType (default=normal). "normal" is the original stochastic equilibrium, "social" is the social risk agent poblem, and "mixed" is other experiments that potentially include both the social risk model and original model.

See other parameter options in parameters.gms

*******************************************************************
We also provide some simple unit test by running 

```
bash unittest.sh
```



