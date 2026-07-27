import csv

def read_csv(file_path):
    with open(file_path, mode='r', newline='') as file:
        reader = csv.reader(file)
        data = [row for row in reader]
    return data
    


if __name__ == "__main__":
    # 0: tree
    # 1: demand
    # 2: algo
    # 3: epsilon
    # 4: lambda
    # 5: seed
    # 6: success
    # 7: time

    timeDictionary = {}
    successDictionary = {}

    for tree in ['tree3']:
        for demand in ['1']:
            for algorithm in ['PD-RU-PATH']:
                for epsilon in ['0','0.01','0.1','1','10']:
                    for lamb in ['0.1','0.3','0.5','0.7','0.9']:
                        timeDictionary[(tree, demand, algorithm, epsilon, lamb)] = [0,0]
                        successDictionary[(tree, demand, algorithm, epsilon, lamb)] = 0
    
    file_path = 'PD-RU-PATH20260213.log'
    data = read_csv(file_path)
    for row in data:
        rowSplit = []
        for element in row:
            element = element.strip()
            rowSplit.append(element.split(' ')[1])
        


        if rowSplit[6] == '1':
            successDictionary[(rowSplit[0], rowSplit[1], rowSplit[2], rowSplit[3], rowSplit[4])] += 1
            timeDictionary[(rowSplit[0], rowSplit[1], rowSplit[2], rowSplit[3], rowSplit[4])][1] += float(rowSplit[7])

        else:
            timeDictionary[(rowSplit[0], rowSplit[1], rowSplit[2], rowSplit[3], rowSplit[4])][0] += float(rowSplit[7])


    for tree in ['tree3']:
        for demand in ['1']:
            for algorithm in ['PD-RU-PATH']:
                for epsilon in ['0','0.01','0.1','1','10']:
                    for lamb in ['0.1','0.3','0.5','0.7','0.9']:
                        print(f"Tree: {tree}, Demand: {demand}, Algorithm: {algorithm}, Epsilon: {epsilon}, Lambda: {lamb}")
                        print(f"  Success Count: {successDictionary[(tree, demand, algorithm, epsilon, lamb)]}")
