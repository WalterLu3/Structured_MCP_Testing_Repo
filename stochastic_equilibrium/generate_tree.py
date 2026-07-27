# tree generation script
import os

if __name__ == "__main__":
    # input parameters
    newTreeName = "tempTree"
    timeStage = 3
    childPerNode = 5

    # calcualte total number of nodes (exclude root)
    tempNodeNum = 1
    totalNodeNum = 0
    for i in range(1,timeStage):
        tempNodeNum = tempNodeNum * childPerNode
        totalNodeNum += tempNodeNum

    # run gams script to generate tree
    os.system(f"gams generate_tree.gms --timeStages={timeStage-1} --childNum={childPerNode} --totalNodeNum={totalNodeNum} --newTreeName={newTreeName}")

    
    
