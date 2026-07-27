#!/bin/bash

mkdir result

for problemNum in 1 2 3 4 5 6 7 8 9 10; do
	gams readvi.gms --filename=vimod$problemNum optfile=13 > result/pnewton_problem$problemNum.log
	gams readvi.gms --filename=vimod$problemNum optfile=11 > result/pathvi_problem$problemNum.log
	gams readvi.gms --filename=vimod$problemNum optfile=12 > result/none_problem$problemNum.log
done

