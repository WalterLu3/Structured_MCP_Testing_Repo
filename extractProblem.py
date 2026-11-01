# List available problem instances or extract a selected instance.

import argparse
import subprocess
import sys
from pathlib import Path


# define the arguments to be parsed
def parse_arguments():
    parser = argparse.ArgumentParser(
        description="List or extract MCP, VI."
    )

    subparsers = parser.add_subparsers(dest="command", required=True)

    extract_parser = subparsers.add_parser(
        "extract", help="Extract a problem instance."
    )
    list_parser = subparsers.add_parser(
        "list", help="List available problem instances."
    )
    list_parser.add_argument(
        "--type",
        required=True,
        choices=["MCP", "VI"],
        help="Category of problems to list.",
    )

    extract_parser.add_argument(
        "--type",
        type=str,
        required=True,
        choices=[
            "MCP",
            "VI",
        ],
        help="Category of problem to generate.",
    )

    extract_parser.add_argument(
        "--select",
        required=True,
        type=str,
        default=None,
        help="Name of the MCP or VI problem instance.",
    )

    extract_parser.add_argument(
        "--dimension",
        type=int,
        default=None,
        help="Dimension of the selected MCP or VI problem.",
    )

    extract_parser.add_argument(
        "--nchildren",
        type=int,
        default=None,
        help="Number of children of each nonterminal scenario-tree node.",
    )

    extract_parser.add_argument(
        "--nstage",
        type=int,
        default=None,
        help="Number of stages in the scenario tree.",
    )

    extract_parser.add_argument(
        "--data",
        type=str,
        choices=["tree2", "tree3"],
        default=None,
        help="Scenario-tree dataset for stochastic equilibrium problems.",
    )

    extract_parser.add_argument(
        "--quad",
        type=float,
        default=None,
        help="Weight of the quadratic term in the stage-cost function.",
    )

    extract_parser.add_argument(
        "--lambda",
        dest="lambda_",
        type=float,
        default=None,
        help="Risk-aversion weight in [0, 1].",
    )

    extract_parser.add_argument(
        "--alpha",
        type=float,
        default=None,
        help="CVaR confidence-level parameter in [0, 1].",
    )

    extract_parser.add_argument(
        "--demandType",
        type=int,
        choices=[1, 2, 3],
        default=None,
        help="Demand-function type.",
    )

    extract_parser.add_argument(
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
    args = parse_arguments()
    base_dir = Path(__file__).resolve().parent

    if args.command == "list":
        problem_dir = base_dir / args.type
        for path in sorted(problem_dir.glob("*.gms")):
            if path.is_file():
                print(path.stem)

    elif args.command == "extract":
        print_arguments(args)
        script = base_dir / args.type / "extractInstance.py"
        command = [sys.executable, str(script)]

        for name, value in vars(args).items():
            if name == "command" or value is None:
                continue

            flag = "lambda" if name == "lambda_" else name
            command += [f"--{flag}", str(value)]

        subprocess.run(command, check=True)
