#!/bin/bash

mkdir result

cp path.op3 path.op3_temp

echo "factorization_library_name $1" >> path.op3

for filePath in instances/* ; do
    fileName=$(basename "$filePath")
    gams visolve.gms --iname=instances/$fileName optfile=1 > result/highs-$fileName.log
    gams visolve.gms --iname=instances/$fileName optfile=2 > result/lusol-$fileName.log
    gams visolve.gms --iname=instances/$fileName optfile=3 > result/umfpack-$fileName.log
    gams visolve.gms --iname=instances/$fileName optfile=4 > result/blulusol-$fileName.log
    gams visolve.gms --iname=instances/$fileName optfile=5 > result/conopt-$fileName.log
done

cp path.op3_temp path.op3

rm path.op3_temp