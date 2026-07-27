#!/bin/bash

mkdir result

for problemNum in 1 2 3 4 5 6 7; do
	gams genlingnep$problemNum.gms optfile=1 > result/pnewton_problem$problemNum.log
	gams mcp.gms mcp=pathvicrash optfile=1 > result/pathvi_problem$problemNum.log
done

