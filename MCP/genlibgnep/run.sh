#!/bin/bash

mkdir result

cp path.op3 path.op3_temp

echo "factorization_library_name $1" >> path.op3

gams genlingnep1.gms --dimension=$dimension optfile=1 > result/highs-genlingnep1.log
gams genlingnep2.gms --dimension=$dimension optfile=2 > result/lusol-genlingnep2.log
gams genlingnep3.gms --dimension=$dimension optfile=3 > result/umfpack-genlingnep3.log
gams genlingnep4.gms --dimension=$dimension optfile=4 > result/blulusol-genlingnep4.log
gams genlingnep5.gms --dimension=$dimension optfile=5 > result/conopt-genlingnep5.log


cp path.op3_temp path.op3

rm path.op3_temp