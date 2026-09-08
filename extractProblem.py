# This script extracts a specific problem instance
# from the instances folders, and put it in the
# tempFolder.

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
        required=True,
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

    parser.add_argument(
        "--nchildren",
        type=int,
        default=None,
        help="Number of children of each nonterminal scenario-tree node.",
    )

    parser.add_argument(
        "--nstage",
        type=int,
        default=None,
        help="Number of stages in the scenario tree.",
    )

    parser.add_argument(
        "--data",
        type=str,
        choices=["tree2", "tree3"],
        default=None,
        help="Scenario-tree dataset for stochastic equilibrium problems.",
    )

    parser.add_argument(
        "--quad",
        type=float,
        default=None,
        help="Weight of the quadratic term in the stage-cost function.",
    )

    parser.add_argument(
        "--lambda",
        dest="lambda_",
        type=float,
        default=None,
        help="Risk-aversion weight in [0, 1].",
    )

    parser.add_argument(
        "--alpha",
        type=float,
        default=None,
        help="CVaR confidence-level parameter in [0, 1].",
    )

    parser.add_argument(
        "--demandType",
        type=int,
        choices=[1, 2, 3],
        default=None,
        help="Demand-function type.",
    )

    parser.add_argument(
        "--randomSeed",
        type=int,
        default=None,
        help="Random seed used during data generation.",
    )

    return parser.parse_args()


def print_arguments(args):

    print("Command-line arguments:")
    for name, value in vars(args).items():
        print(f"  {name} = {value}")


if __name__ == "__main__":
    # parse arguments
    args = parse_arguments()

    # print arguments
    print_arguments(args)

    # set up the base directory
    base_dir = Path(__file__).resolve().parent

    # Start preparing script
    script = base_dir / args.type / "extractInstance.py"

    command = [
        sys.executable, # python interpreter
        str(script),
    ]

    for name, value in vars(args).items():
        if value != None:
            command += ["--" + name, str(value)]

    subprocess.run(command, check=True)


