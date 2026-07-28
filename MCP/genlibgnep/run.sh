#!/bin/bash
set -euo pipefail

# Directory containing run.sh:
# cur/MCP/genlingnep
script_dir="$(cd "$(dirname "$0")" && pwd)"

# Project root:
# cur/MCP/genlingnep -> cur/MCP -> cur
root_dir="$(cd "$script_dir/../.." && pwd)"

output_dir="$root_dir/problem"

mkdir -p "$output_dir"

for model in \
    genlingnep1 \
    genlingnep2 \
    genlingnep3 \
    genlingnep4 \
    genlingnep5
do
    echo "Generating ${model}.gms..."

    (
        cd "$script_dir"

        gams "${model}.gms" \
            action=c \
            dumpOpt=21

        mv "${model}.dmp" \
            "$output_dir/${model}.gms"
    )
done

echo "Generated files in: $output_dir"