#!/bin/bash
set -euo pipefail

# Directory containing this script:
# cur/MCP/bratu
script_dir="$(cd "$(dirname "$0")" && pwd)"

# Project root:
# cur/MCP/bratu -> cur/MCP -> cur
root_dir="$(cd "$script_dir/../.." && pwd)"

output_dir="$root_dir/problem"
model_file="$script_dir/bratu.gms"

mkdir -p "$output_dir"

for dimension in 76 100 150 200; do
    echo "Generating Bratu dimension ${dimension}..."

    (
        cd "$script_dir"

        gams "$model_file" \
            --dimension="$dimension" \
            action=c \
            dumpOpt=21

        mv "bratu.dmp" \
            "$output_dir/bratu_dimension_${dimension}.gms"
    )
done

echo "Generated files in: $output_dir"
