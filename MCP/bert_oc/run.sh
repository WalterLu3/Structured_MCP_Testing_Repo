#!/bin/bash
set -euo pipefail

# Directory containing run.sh:
# cur/MCP/bert_oc
script_dir="$(cd "$(dirname "$0")" && pwd)"

# Go two levels upward:
# cur/MCP/bert_oc -> cur/MCP -> cur
root_dir="$(cd "$script_dir/../.." && pwd)"

output_dir="$root_dir/problem"
model_file="$script_dir/bert_oc.gms"

mkdir -p "$output_dir"

for dimension in 8000; do
    echo "Generating dimension ${dimension}..."

    # Run GAMS inside bai_haung so the .dmp location is predictable.
    (
        cd "$script_dir"

        gams "$model_file" \
            --dimension="$dimension" \
            action=c \
            dumpOpt=21

        mv "bert_oc.dmp" \
            "$output_dir/bert_oc_${dimension}.gms"
    )
done

echo "Generated files in: $output_dir"