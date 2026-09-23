import argparse
import subprocess
import sys
from pathlib import Path

# define the arguments to be parsed
def parse_arguments():
    parser = argparse.ArgumentParser(
        description="Generate MCP, VI, stochastic optimization, or stochastic equilibrium problems."
    )

    parser.add_argument(
        "--type",
        type=str,
        required=True,
        choices=[
            "MCP",
            "VI",
            "StochasticOptimization",
            "StochasticEquilibrium",
        ],
        help="Category of problem to generate.",
    )

    parser.add_argument(
        "--select",
        type=str,
        default=None,
        help="Name of the MCP or VI problem instance.",
    )

    parser.add_argument(
        "--dimension",
        type=int,
        default=None,
        help="Dimension of the selected MCP or VI problem.",
    )

    return parser.parse_args()

if __name__ == "__main__":
    args = parse_arguments()

    # set up the base directory
    base_dir = Path(__file__).resolve().parent

    # Start preparing script
    fileName = args.select + ".gms"
    filePATH = base_dir / fileName

    # Start preparing script
    command = [
        "gams", # python interpreter
        filePATH,
        "action=c",
        "dumpOpt=21",
    ]

    for name, value in vars(args).items():
        if name != "select":
            command += ["--{NAME}={VALUE}".format(NAME=name,VALUE=value)]

    #subprocess.run(command, check=True)

    subprocess.run(command, check=True)

    # fileName rename
    dump_file = base_dir.parent / (args.select + ".dmp")
    temp_gms = base_dir.parent / "tempMCP.gms"

    dump_file.rename(temp_gms)