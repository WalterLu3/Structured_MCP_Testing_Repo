$ontext
Experiment to check if equilibrium formulation is solved directly
$offtext

option emp=reshop;

option reslim=120;

set loopN /l1*l%iterationLimit%/;

* step 1 run PD with multiple loops:
riskProb.l(n) = prob(n);


$ontext
display objPrimal.l;




embeddedCode python:
import graphviz

def drawTree(dot, nodes, arcs, y, objdual, f, z, floodCost, lowCost):
    dot.attr('node', shape='circle', style='filled', fillcolor='lightblue', fontname='Helvetica')
    dot.attr('edge', color='gray40', arrowsize='0.8')

    for node in nodes:
        if node == "n1":
            stage_cost = 0
        else:
            stage_cost = f.get(node, 0) * floodCost + z.get(node, 0) * lowCost
        label = "\n".join((
            node,
            f"disbenefit: {objdual.get(node, 0):,.5g}",
            f"stage cost: {stage_cost:,.5g}",
        ))
        dot.node(node, label=label)

    for start_node, end_node in arcs:
        dot.edge(start_node, end_node, label=f"{y.get(end_node, 0):,.5g}")


db = gams.db

nodes = [rec.keys[0] for rec in db["n"]]
arcs = [(rec.keys[0], rec.keys[1]) for rec in db["succ"]]

floodCost = db["floodCost"].first_record().value
lowCost = db["lowCost"].first_record().value

y = {}
objdual = {}
f = {}
z = {}

for rec in db["riskprob"]:
    y[rec.keys[0]] = rec.level

for rec in db["objdual"]:
    objdual[rec.keys[0]] = rec.level

for rec in db["f"]:
    f[rec.keys[0]] = rec.level

for rec in db["z"]:
    z[rec.keys[0]] = rec.level

print(f"Found {len(nodes)} nodes and {len(arcs)} arcs.")

dot = graphviz.Digraph('GamsTree', comment='GAMS Tree Visualization')
dot.attr(rankdir='LR', size='10,8', label='Tree with objdual and stage cost', fontsize='20')

drawTree(dot, nodes, arcs, y, objdual, f, z, floodCost, lowCost)

output_filename = 'seed2_pd_4'
try:
    dot.render(output_filename, view=True, format='pdf', cleanup=True)
    print(f"Successfully created graph visualization: '{output_filename}.pdf'")
except Exception as e:
    print(f"Error during Graphviz rendering: {e}")

endEmbeddedCode


$offtext


embeddedCode reshop:
primalNode: min objPrimal L(n) F(n) R(n) Z(n) objPrimalEqu deflvl(n)
dualNode(n)$(not isLeafNode(n)): max objDual(n) riskProb(child)$(succ(n,child)) objDualEqu(n) convexCombEqu(n)
equ: Nash(primalNode, dualNode(n)$(not isLeafNode(n)))
endEmbeddedCode


solve mincostEMPManual using EMP;

scalar t_used;
t_used = timeElapsed;

display t_used;