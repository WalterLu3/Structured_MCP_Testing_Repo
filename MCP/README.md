This is the folder for storing testing problem for basis package.
Currently, there is only 1 MCP problem that has nontrivial basis
time. More basis package to look for.


Each folder contains a set of problems that can be tested on basis packages. The tested basis options are
1. HIGHS (.opt)
2. LUSOL (.op2)
3. UMFPACK (.op3)
4. BLU_LUSOL (.op4)
5. CONOPT (.op5)

Most of the examples here allows us to increase the size of the problem. In order to run each experiment,

First,

`cd <problem folder>`

`bash run.sh UMFPACK_Library_PATH`

The resulting log file will be storeed in `<problem folder>/result/`

** Currently me9x9 cannot be executed in this way, I will make some change about this asap.


