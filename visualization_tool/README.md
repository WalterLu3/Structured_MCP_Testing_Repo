This repo contains a python file to visualize the Jacobian.

You can run it by executing

`python3 dumpJacobian_tool.py`

Suppose we want to generate the Jacobian of the model, MCP.gms.

Required files (the routine will look for the following files):
1. d.gdx   
2. h.gdx
    (The above two file can be accessed by running convert solver on MCP.gms. See https://forum.gams.com/t/access-to-hessian-jacobian-matrices-at-optimal-point-ipopth/3542)
3. poly.txt : this one specifies the names of user specified polyhedral constraints of MCP.gms in each line.

Output:
1. originalJacobian.png : the original Jacobian before permutation.
2. permutedJacobian.png : permuted Jacobian by putting constraints specified in poly.txt at the end.
