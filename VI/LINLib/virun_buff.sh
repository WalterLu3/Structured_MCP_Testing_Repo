#!/bin/bash

# This file runs experiment for a single instance in LINLIB
# We run the original path and pathvi as crash

mkdir logs

echo "experiment start" > logs/iterations.log

# example values of d are the data file name in instance/
#d="25fv47.gdx"
#d="aa01.gdx"

d=$1

echo "running example $d"

echo $d >> logs/iterations.log

echo "------normal path------\n" > logs/$d.log
echo "PATH normal" >> logs/iterations.log

gams visolve.gms --iname=instances/$d Suppress=1 >> logs/$d.log

echo "------pathvi as crash------\n" >> logs/$d.log
echo "PATH crash" >> logs/iterations.log

if [ -e "mcp_formulation.gms" ] ; then
    gams mcp_formulation.gms mcp=pathvicrash optfile=1 Suppress=1 >> logs/$d.log
    rm mcp_formulation.gms
else
    echo "mcp reformulation was not created for $d. There must be something wrong with this model. Skip the PATHVI crash experiment for it."
fi


# echo "------pathvi as EMP------\n" >> logs/$d.log
# echo "PATH emp" >> logs/iterations.log
# gams youngdaevisolve.gms --iname=instances/$d Suppress=1 >> logs/$d.log


