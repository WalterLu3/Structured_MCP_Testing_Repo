#!/bin/bash

mkdir result

cp path.op3 path.op3_temp

echo "factorization_library_name $1" >> path.op3

for dimension in 250 500 750 1000 ; do
    gams opt_cont.gms --dimension=$dimension optfile=1 > result/highs-$dimension.log
    gams opt_cont.gms --dimension=$dimension optfile=2 > result/lusol-$dimension.log
    gams opt_cont.gms --dimension=$dimension optfile=3 > result/umfpack-$dimension.log
    gams opt_cont.gms --dimension=$dimension optfile=4 > result/blulusol-$dimension.log
    gams opt_cont.gms --dimension=$dimension optfile=5 > result/conopt-$dimension.log
done

cp path.op3_temp path.op3

rm path.op3_temp