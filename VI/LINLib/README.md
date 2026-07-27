# LINLib Model Library

This is a large collection of linear and quadratic models. Some of the the instances also contain discrete variables. Models are from https://github.com/GAMS-dev/gamsworld/tree/master/LINLib (details of each model can also found in this link)


## What does the experiment do?

We reformulate an LP problem as an AVI problem, and solve it using PATH and PATHVI as crash method.

You can run the experiment in the following way.

`bash virun_buff.sh <instance_name>`

where instance_name is the name of the GDX file in `instances/` folder (e.g. `10teams.gdx`).

** Note that the script will only run on the problems which are LP problems and only contain continuous variables, as there are some MIP problems and quadratic problems in LINLIB.

The result will be stored in a created folder `logs/` and the running log of PATH and PATHVI as crash method will be concatenated and stored in `logs/<instance_name>.log`.

## Change of PATH options and PATHVI options

The normal PATH option is specified in path.opt and the PATHVI as crash is specified in pathvicrash.opt.

