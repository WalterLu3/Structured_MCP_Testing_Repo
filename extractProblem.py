"""List standalone MCP/VI models or extract one as tempMCP.gms."""

import argparse
import subprocess
import sys
import tempfile
from pathlib import Path


BASE_DIR = Path(__file__).resolve().parent


# define the arguments to be parsed
def parse_arguments(argv=None):
    parser = argparse.ArgumentParser(
        description="List or extract standalone MCP and VI models."
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

    return parser.parse_args(argv)


def print_arguments(args):

    print("Command-line arguments:")
    for name, value in vars(args).items():
        print(f"  {name} = {value}")


def extract_problem(args, base_dir):
    """Compile the selected source directly and publish its preprocessed model."""
    if (not args.select or args.select in {".", ".."}
            or Path(args.select).name != args.select or "\\" in args.select):
        raise ValueError("--select must be a model name without a directory or .gms extension")

    model = base_dir / args.type / f"{args.select}.gms"
    if not model.is_file():
        raise FileNotFoundError(
            f"Model not found: {model}. "
            f"Use 'list --type {args.type}' to see available models."
        )

    parameters = []
    for name, value in vars(args).items():
        if name in {"command", "type", "select"} or value is None:
            continue
        flag = "lambda" if name == "lambda_" else name
        parameters.append(f"--{flag}={value}")

    # dumpOpt=21 writes <input name>.dmp in the working directory. Set an
    # existing dump aside so it cannot be mistaken for this compilation's output.
    dump = base_dir / f"{args.select}.dmp"
    if dump.exists() and not dump.is_file() and not dump.is_symlink():
        raise RuntimeError(f"Cannot write the GAMS dump: {dump} is not a file")
    with tempfile.TemporaryDirectory(prefix=".extractProblem-", dir=base_dir) as directory:
        previous_dump = Path(directory) / "previous.dmp"
        if dump.exists() or dump.is_symlink():
            dump.replace(previous_dump)
        command = [
            "gams", str(model), "action=c", "dumpOpt=21",
            *parameters,
        ]
        try:
            try:
                subprocess.run(command, cwd=base_dir, check=True)
            except FileNotFoundError as error:
                raise RuntimeError("GAMS executable 'gams' was not found on PATH") from error
            if not dump.is_file() or dump.stat().st_size == 0:
                raise RuntimeError("GAMS completed without creating the preprocessed model")
            output = base_dir / "tempMCP.gms"
            dump.replace(output)
        finally:
            if previous_dump.exists() or previous_dump.is_symlink():
                previous_dump.replace(dump)
            elif dump.exists():
                dump.unlink()
    return output


def main(argv=None):
    args = parse_arguments(argv)

    if args.command == "list":
        problem_dir = BASE_DIR / args.type
        for path in sorted(problem_dir.glob("*.gms")):
            if path.is_file():
                print(path.stem)
        return 0

    print_arguments(args)
    try:
        output = extract_problem(args, BASE_DIR)
    except subprocess.CalledProcessError as error:
        print(f"Extraction failed: GAMS exited with status {error.returncode}.", file=sys.stderr)
        return error.returncode
    except (OSError, RuntimeError, ValueError) as error:
        print(f"Extraction failed: {error}", file=sys.stderr)
        return 1
    print(f"Saved extracted model to {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
