#!/bin/bash
set -euo pipefail

# Directory containing run.sh:
# cur/MCP/bai_haung
script_dir="$(cd "$(dirname "$0")" && pwd)"

# Go two levels upward:
# cur/MCP/bai_haung -> cur/MCP -> cur
root_dir="$(cd "$script_dir/../.." && pwd)"

output_dir="$root_dir/problem"
model_file="$script_dir/bai_haung.gms"

mkdir -p "$output_dir"

for dimension in 50 100 150 200 250 300; do
    echo "Generating dimension ${dimension}..."

    # Run GAMS inside bai_haung so the .dmp location is predictable.
    (
        cd "$script_dir"

        gams "$model_file" \
            --dimension="$dimension" \
            action=c \
            dumpOpt=21

        mv "bai_haung.dmp" \
            "$output_dir/bai_haung_dimension_${dimension}.gms"
    )
done

echo "Generated files in: $output_dir"