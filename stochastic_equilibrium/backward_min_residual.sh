#!/usr/bin/env bash

output_csv="residuals_pd_min.csv"
log_file="test.log"
lst_file="main.lst"

echo "randomSeed,minResidual" > "$output_csv"

for random_seed in $(seq 1 500); do
    echo "Running randomSeed=${random_seed}..."

    gams main.gms \
        --data=2StageExmapleTree_3 \
        --quad=0.1 \
        --demandType=1 \
        --lambda=0.1 \
        --algorithm=PD \
        --iterationLimit=50 \
        --randomSeed="$random_seed" \
        > "$log_file" 2>&1

    min_residual=$(grep -E '^----.*PARAMETER minResidual.*=' "$lst_file" \
        | tail -n 1 \
        | awk -F'=' '{gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2}')

    min_residual=${min_residual:-NA}

    echo "${random_seed},${min_residual}" >> "$output_csv"
done

rm -f "$log_file"

echo "Results written to ${output_csv}"