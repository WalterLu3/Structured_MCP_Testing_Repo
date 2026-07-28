#!/bin/bash
set -euo pipefail

# Directory containing this script:
# cur/MCP/opt_cont
script_dir="$(cd "$(dirname "$0")" && pwd)"

# Project root:
# cur/MCP/opt_cont -> cur/MCP -> cur
root_dir="$(cd "$script_dir/../.." && pwd)"

output_dir="$root_dir/problem"
model_file="$script_dir/opt_cont.gms"

mkdir -p "$output_dir"

for dimension in 250 500 750 1000; do
    echo "Generating opt_cont dimension ${dimension}..."

    (
        cd "$script_dir"

        gams "$model_file" \
            --dimension="$dimension" \
            action=c \
            dumpOpt=21

        mv "opt_cont.dmp" \
            "$output_dir/opt_cont_dimension_${dimension}.gms"
    )
done

echo "Generated files in: $output_dir"
