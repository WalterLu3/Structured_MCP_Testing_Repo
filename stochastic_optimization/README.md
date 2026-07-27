This folder stores the stochastic optimization experiment in celar lake.

1. clearlak-ecvarup_main.gms : the main file to run. This file also contains all the parameters.
2. clearlak-ecvarup_model.gms: the file containing the submodels related to solving the Clear Lake example.
3. experiments/ : a repo that contains all algorithms/experiments that operate on the stochastic optimization models

Example: run
```
gams clearlak-ecvarup_main.gms --experimentType=PD-PATH --nstage=6 --nchildren=3 --randomSeed=5
```

The above will run an example with:
1. 6 time stages
2. Each scenario node has 3 children nodes
3. all the random data are generated with seed = 5
4. algorithm PD-PATH  (options: RU, RU-PATH, Equilibrium,  PD-PATH, PD-PATH-LP, PD-PATH-NLP, etc. See other algorithm options in clearlak-ecvarup_main.gms)



