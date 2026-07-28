#!/bin/bash
set -euo pipefail

# Directory containing run.sh:
# cur/MCP/dirkse2
script_dir="$(cd "$(dirname "$0")" && pwd)"

# Go two levels upward:
# cur/MCP/dirkse2 -> cur/MCP -> cur
root_dir="$(cd "$script_dir/../.." && pwd)"

output_dir="$root_dir/problem"
model_file="$script_dir/dirkse2.gms"

mkdir -p "$output_dir"

for dimension in 25 30 35; do
    echo "Generating dimension ${dimension}..."

    # Run GAMS inside bai_haung so the .dmp location is predictable.
    (
        cd "$script_dir"

        gams "$model_file" \
            --dimension="$dimension" \
            action=c \
            dumpOpt=21

        mv "dirkse2.dmp" \
            "$output_dir/dirkse2_${dimension}.gms"
    )
done

echo "Generated files in: $output_dir"