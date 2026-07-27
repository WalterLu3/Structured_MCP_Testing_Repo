#!/bin/bash

mkdir result

cp path.op3 path.op3_temp

echo "factorization_library_name $1" >> path.op3

for dimension in 8000 ; do

#    gams bert_oc.gms --dimension=$dimension optfile=1 > result/highs-$dimension.log
    gams bert_oc.gms --dimension=$dimension optfile=2 > result/lusol-$dimension.log
    gams bert_oc.gms --dimension=$dimension optfile=3 > result/umfpack-$dimension.log
    gams bert_oc.gms --dimension=$dimension optfile=4 > result/blulusol-$dimension.log
    gams bert_oc.gms --dimension=$dimension optfile=5 > result/conopt-$dimension.log
done

cp path.op3_temp path.op3

rm path.op3_temp