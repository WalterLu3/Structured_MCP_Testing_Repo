import gams.transfer as gt
import matplotlib.pyplot as plt


# get files
jacobian = gt.Container("h.gdx")
dictonary = gt.Container("d.gdx")

# totolProblem size
problemSize = jacobian.data["e"].shape[0]

# read in poly set. In the namespace of GAMS 
polySet = {}
with open("poly.txt", "r") as f:
    for line in f:
        polySet[line[:-1].replace("'","")] = 1


# complementary paris are in the namespace of PATH
complementaryEquToVar = {}
complementaryVarToEqu = {}
for index, row in  jacobian.data["mcpmap"].records.iterrows():
   complementaryEquToVar[row['uni_0']] = row['uni_1']
   complementaryVarToEqu[row['uni_1']] = row['uni_0']

# namespace mapping
varPATHtoGAMS = {}
varGAMStoPATH = {}
equPATHtoGAMS = {}
equGAMStoPATH = {}

for index, row in  jacobian.data["i"].records.iterrows():
    equPATHtoGAMS[row['uni']] = row['element_text']
    equGAMStoPATH[row['element_text']] = row['uni']


for index, row in  jacobian.data["j"].records.iterrows():
    varPATHtoGAMS[row['uni']] = row['element_text']
    varGAMStoPATH[row['element_text']] = row['uni']

# reassigning index for symmetric permutation (PATH namespace)
equIndex = {}
varIndex = {}

# calculate the number of poly rows
total_poly = 0
for key in equGAMStoPATH:
    if key in polySet:
        total_poly += 1

primalIndex = 1
dualIndex = problemSize - total_poly + 1

# loop over all the equations in GAMS namespace
for key in equGAMStoPATH:
    # if it is polyhedral, add
    if key in polySet:
        equIndex[equGAMStoPATH[key]] = dualIndex
        varIndex[complementaryEquToVar[equGAMStoPATH[key]]] = dualIndex
        dualIndex += 1
    else:
        equIndex[equGAMStoPATH[key]] = primalIndex
        varIndex[complementaryEquToVar[equGAMStoPATH[key]]] = primalIndex
        primalIndex += 1


# coordinates for scatter plot
x = []
y = []

#original jacobian
colors = []
JacobianValues = {}
for index, row in  jacobian.data["A"].records.iterrows():
    if row["value"] == 0:
       continue
    # if 34 <= int(row['i'][1:]) <= 119 or 34 <= int(complementaryVarToEqu[row['j']][1:]) <= 119:
    #     colors.append('red')
    # else:
    #     colors.append('blue')
    y.append(problemSize + 1 -int(row['i'][1:]))
    #y.append(problemSize + 1 -int(row['i'][1:]))
    x.append(int(complementaryVarToEqu[row['j']][1:]))

    rIndex = problemSize + 1 -int(row['i'][1:])
    cIndex = int(complementaryVarToEqu[row['j']][1:])
    JacobianValues[rIndex, cIndex] = row['value']

nonSkewRows = set()
for i in range(len(x)):
    skewRow = problemSize-x[i]+1
    skewCol = problemSize-y[i]+1
    if (skewRow,skewCol) in JacobianValues and JacobianValues[skewRow,skewCol] == -JacobianValues[y[i],x[i]]:
        colors.append('red')
    else:
        colors.append('blue') 
        nonSkewRows.add(y[i])

# Plotting the points
plt.scatter(x, y, c = colors, s=5)
#plt.scatter(x, y, s=5)

# Adjust layout to reduce margins
plt.tight_layout()

# Set the aspect ratio to be equal (square)
plt.gca().set_aspect('equal', adjustable='box')

# Adding labels and title
plt.xlabel('')
plt.ylabel('')
plt.title('')

# Show the plot
#plt.show()
plt.savefig("originalJacobian.png", bbox_inches='tight')

plt.close()

#new Jacobian

# coordinates for scatter plot
x = []
y = []

colors = []
JacobianValues = {}
for index, row in  jacobian.data["A"].records.iterrows():
    if row["value"] == 0:
       continue

    y.append(problemSize + 1 - equIndex[row['i']])
    x.append(varIndex[row['j']])

    rIndex = problemSize + 1 - equIndex[row['i']]
    cIndex = varIndex[row['j']]
    JacobianValues[rIndex, cIndex] = row['value']

nonSkewRows = set()
for i in range(len(x)):
    skewRow = problemSize-x[i]+1
    skewCol = problemSize-y[i]+1
    if (skewRow,skewCol) in JacobianValues and JacobianValues[skewRow,skewCol] == -JacobianValues[y[i],x[i]]:
        colors.append('red')
    else:
        colors.append('blue') 
        nonSkewRows.add(y[i])

# Plotting the points
plt.scatter(x, y, c = colors, s=5)
#plt.scatter(x, y, s=5)

# add lines for jacobian structures
plt.axhline(y= total_poly + 0.5, color='black', linestyle='--', linewidth=1)
plt.axvline(x= problemSize - total_poly + 0.5, color='black', linestyle='--', linewidth=1)

# Adjust layout to reduce margins
plt.tight_layout()

# Set the aspect ratio to be equal (square)
plt.gca().set_aspect('equal', adjustable='box')

# Adding labels and title
plt.xlabel('')
plt.ylabel('')
plt.title('')

# Show the plot
#plt.show()
plt.savefig("permutedJacobian.png", bbox_inches='tight')

plt.close()