#!/bin/bash

# unit test

### test 1 

echo "test 1: 3 easy examples on PATH solve and Dynamic solve"

for seed in 1 2 3; do
    for algorithm in PATH dynamic; do

        # if the checking_answer.gdx exists, remove it
        if [ -f checking_answer.gdx ]; then
            rm checking_answer.gdx
        fi

        gams main.gms --lambda=0.1 --epsilon=10 --seed=$seed --demandType=1 --algorithm=$algorithm --saveSolutionAsGdx=TRUE > tempResult.log
        gams compare.gms --seed=$seed > tempResult.log
        residual=$(grep "PARAMETER checkingResidual" compare.lst | awk -F'=' '{print $2}' | awk '{print $1}')

        if awk -v r="$residual" 'BEGIN { exit !(r+0 < 1e-1) }'; then
            echo "test 1: seed $seed, $algorithm algorithm: PASS with residual $residual"
        else
            echo "test 1: seed $seed, $algorithm algorithm: FAIL with residual $residual"
        fi
    done
done

