"""Register types and models, list models, or extract as tempMCPs/<name>.gms.

The problem catalog is stored in problems.json beside this script.
Each type has a folder beside this script. Extraction calls GAMS
directly to expand the selected source and its compile-time parameters.
The expanded source keeps its solve statements for the user to run later.
"""

import argparse
import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


# Resolve paths from the script location, even when invoked from another folder.
BASE_DIR = Path(__file__).resolve().parent


def validate_type_name(value):
    """Keep type names to one visible folder component on supported platforms."""
    if not isinstance(value, str) or not re.fullmatch(r"[A-Za-z][A-Za-z0-9_-]*", value):
        raise ValueError("Type names must start with a letter and contain only letters, digits, '_' or '-'")
    return value


def parse_type_name(value):
    """Present invalid type names as normal command-line argument errors."""
    try:
        return validate_type_name(value)
    except ValueError as error:
        raise argparse.ArgumentTypeError(str(error)) from error


def parse_arguments(argv=None):
    """Parse commands; None reads the process's CLI arguments."""
    parser = argparse.ArgumentParser(
        description="Register problem types and files, list models, or extract standalone GAMS models."
    )

    # Listing needs only a category; extraction also requires a model name.
    subparsers = parser.add_subparsers(dest="command", required=True)

    extract_parser = subparsers.add_parser(
        "extract", help="Extract a problem instance."
    )
    list_parser = subparsers.add_parser(
        "list", help="List registered problem instances available locally."
    )
    list_parser.add_argument(
        "--type",
        required=True,
        type=parse_type_name,
        help="Registered category of problems to list.",
    )

    add_type_parser = subparsers.add_parser(
        "addType", help="Register a problem type and create its folder."
    )
    add_type_parser.add_argument(
        "--type", required=True, type=parse_type_name,
        help="New type name; also the name of its repository folder.",
    )

    add_problem_parser = subparsers.add_parser(
        "addProblem", help="Copy a GAMS problem into a type folder and register it."
    )
    add_problem_parser.add_argument(
        "--type", required=True, type=parse_type_name,
        help="Registered type to which the problem belongs.",
    )
    add_problem_parser.add_argument(
        "--file", required=True, type=Path,
        help="Path to the .gms source file; its filename determines the problem name.",
    )

    # Routing options identify the source file rather than GAMS model parameters.
    extract_parser.add_argument(
        "--type",
        type=parse_type_name,
        required=True,
        help="Type folder containing the model to extract.",
    )

    extract_parser.add_argument(
        "--select",
        required=True,
        type=str,
        default=None,
        help="Name of the problem instance.",
    )

    # None means "not supplied": preserve the default declared by the GAMS model.
    extract_parser.add_argument(
        "--dimension",
        type=int,
        default=None,
        help="Dimension of the selected MCP or VI problem.",
    )

    # Keep the existing optional flags. Each affects only models that reference
    # its corresponding GAMS parameter; extraction forwards supplied values.
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

    # Python reserves "lambda", so argparse stores this option as lambda_.
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
    """Show the selected command and parameter values before compilation."""
    print("Command-line arguments:")
    for name, value in vars(args).items():
        print(f"  {name} = {value}")


def load_registry(base_dir):
    """Read the catalog and validate registered types and problem records."""
    registry = base_dir / "problems.json"
    try:
        data = json.loads(registry.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise ValueError(
            f"Invalid JSON in {registry}: {error.msg} (line {error.lineno})"
        ) from error
    if not isinstance(data, dict) or not isinstance(data.get("problems"), list):
        raise ValueError(f"{registry} must contain a 'problems' array")

    # Accept the original catalog format while migrating types to explicit data.
    categories = data.get("types", ["MCP", "VI"])
    if not isinstance(categories, list):
        raise ValueError(f"{registry}: 'types' must be an array of type names")
    seen_types = set()
    for category in categories:
        validate_type_name(category)
        if category.casefold() in seen_types:
            raise ValueError(f"Duplicate registered type: {category}")
        seen_types.add(category.casefold())

    seen = set()
    for index, record in enumerate(data["problems"], 1):
        if not isinstance(record, dict) or any(
            not isinstance(record.get(field), str) for field in ("name", "type", "file")
        ):
            raise ValueError(f"Problem record {index} needs string fields: name, type, file")
        name, category = record["name"], record["type"]
        if category not in categories:
            raise ValueError(f"Problem record {index}: type '{category}' is not registered")
        if (not name or name in {".", ".."}
                or Path(name).name != name or "\\" in name):
            raise ValueError(f"Problem record {index}: name must be a model name without directories")
        # Keep catalog names consistent with the existing --type/--select lookup.
        expected = f"{category}/{name}.gms"
        if record["file"] != expected:
            raise ValueError(f"Problem record {index}: file must be {expected}")
        key = (category, name)
        if key in seen:
            raise ValueError(f"Duplicate problem registration: {category}/{name}")
        seen.add(key)

    # Missing source files are not a corrupt catalog: large generated models
    # may be registered but absent from a checkout because Git ignores them.
    return {**data, "types": categories}


def load_problem_records(base_dir):
    """Return problem records while retaining the existing catalog reader API."""
    return load_registry(base_dir)["problems"]


def save_registry(base_dir, data):
    """Replace the catalog atomically, preserving its existing file permissions."""
    registry = base_dir / "problems.json"
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w", encoding="utf-8", prefix=".problems-", suffix=".json",
            dir=base_dir, delete=False,
        ) as stream:
            temporary = Path(stream.name)
            json.dump(data, stream, indent=2)
            stream.write("\n")
        temporary.chmod(registry.stat().st_mode & 0o777)
        temporary.replace(registry)
    finally:
        if temporary is not None and temporary.exists():
            temporary.unlink()


def type_folder(category, base_dir):
    """Check the destination folder without changing existing paths or symlinks."""
    for entry in base_dir.iterdir():
        if entry.name.casefold() == category.casefold() and entry.name != category:
            raise ValueError(f"A path already exists as '{entry.name}'; use its exact spelling")
    folder = base_dir / category
    if folder.is_symlink() or (folder.exists() and not folder.is_dir()):
        raise ValueError(f"Type folder must be a real directory: {folder}")
    return folder


def add_type(category, base_dir):
    """Register a type and its folder, rolling back new files if saving fails."""
    validate_type_name(category)
    data = load_registry(base_dir)
    for existing in data["types"]:
        if existing.casefold() == category.casefold():
            raise ValueError(f"Type '{category}' is already registered as '{existing}'")

    folder = type_folder(category, base_dir)
    folder_created = False
    marker_created = False
    marker = folder / ".gitkeep"
    try:
        if not folder.exists():
            folder.mkdir()
            folder_created = True
        # Git does not track empty directories; keep an empty new type portable.
        if not marker.exists() and not marker.is_symlink():
            with marker.open("x"):
                pass
            marker_created = True
        data["types"].append(category)
        save_registry(base_dir, data)
    except BaseException:
        # Remove only files created by this attempt; preserve existing contents.
        if marker_created:
            marker.unlink()
        if folder_created:
            try:
                folder.rmdir()
            except OSError:
                pass  # Another process may have added files; leave them intact.
        raise
    return folder


def add_problem(category, source_file, base_dir):
    """Import one GAMS file and register it, preserving the original source."""
    validate_type_name(category)
    data = load_registry(base_dir)
    if category not in data["types"]:
        available = ", ".join(data["types"]) or "none"
        raise ValueError(
            f"Unknown type '{category}'. Registered types: {available}. "
            "Use addType to register a new type first."
        )

    # Resolve relative source paths from the caller's directory, not the repo.
    supplied = Path(source_file).expanduser()
    if supplied.suffix.lower() != ".gms":
        raise ValueError(f"Source must be a .gms file: {supplied}")
    name = supplied.stem
    if not name or name in {".", ".."} or Path(name).name != name or "\\" in name:
        raise ValueError("Source filename must be a problem name without directories")
    source = supplied.resolve(strict=True)
    if not source.is_file():
        raise ValueError(f"Source must be a regular .gms file: {supplied}")
    for record in data["problems"]:
        if record["type"] == category and record["name"].casefold() == name.casefold():
            raise ValueError(f"Problem '{category}/{name}' is already registered as '{record['name']}'")

    folder = type_folder(category, base_dir)
    target = folder / f"{name}.gms"
    if folder.exists():
        for entry in folder.iterdir():
            if entry.name.casefold() == target.name.casefold() and entry.name != target.name:
                raise ValueError(f"A model path already exists as '{entry.name}'; use its exact spelling")
    # A file already in its correct folder can be registered in place. An
    # unrelated destination must never be overwritten by an import.
    in_place = target.is_file() and not target.is_symlink() and source.samefile(target)
    if (target.exists() or target.is_symlink()) and not in_place:
        raise ValueError(f"Destination already exists: {target}. Register that file directly or choose another filename.")

    record = {"name": name, "type": category, "file": f"{category}/{name}.gms"}
    folder_created = False
    copy_created = False
    try:
        if not folder.exists():
            folder.mkdir()
            folder_created = True
        if not in_place:
            # Exclusive creation also protects against a destination appearing
            # after validation. Stream large models rather than loading them whole.
            with source.open("rb") as reader, target.open("xb") as writer:
                copy_created = True
                shutil.copyfileobj(reader, writer)
        data["problems"].append(record)
        save_registry(base_dir, data)
    except BaseException:
        # Existing in-place files and the user's original source are preserved.
        if copy_created:
            target.unlink()
        if folder_created:
            try:
                folder.rmdir()
            except OSError:
                pass
        raise
    return record


def extract_problem(args, base_dir):
    """Expand a GAMS model and return tempMCPs/<selected name>.gms."""
    validate_type_name(args.type)
    # A selection is a model name, not a path outside the chosen model folder.
    if (not args.select or args.select in {".", ".."}
            or Path(args.select).name != args.select or "\\" in args.select):
        raise ValueError("--select must be a model name without a directory or .gms extension")

    # Models must already exist as .gms files; LINLib generation is a separate step.
    model = base_dir / args.type / f"{args.select}.gms"
    if not model.is_file():
        raise FileNotFoundError(
            f"Model not found: {model}. "
            f"Use 'list --type {args.type}' to see available models."
        )

    # Forward only modeling options that the user actually supplied. Routing
    # options and omitted values must not override model defaults in GAMS.
    parameters = []
    for name, value in vars(args).items():
        if name in {"command", "type", "select"} or value is None:
            continue
        flag = "lambda" if name == "lambda_" else name  # Restore the GAMS spelling.
        parameters.append(f"--{flag}={value}")

    # dumpOpt=21 writes <input name>.dmp in the working directory. Set an
    # existing dump aside so it cannot be mistaken for this compilation's output.
    dump = base_dir / f"{args.select}.dmp"
    if dump.exists() and not dump.is_file() and not dump.is_symlink():
        raise RuntimeError(f"Cannot write the GAMS dump: {dump} is not a file")
    with tempfile.TemporaryDirectory(prefix=".extractProblem-", dir=base_dir) as directory:
        # Preserve any pre-existing dump and restore it after this extraction.
        previous_dump = Path(directory) / "previous.dmp"
        if dump.exists() or dump.is_symlink():
            dump.replace(previous_dump)
        # action=c compiles without running solve statements. dumpOpt=21 writes
        # the expanded source, including any embedded poly.txt writer.
        command = [
            "gams", str(model), "action=c", "dumpOpt=21",
            *parameters,
        ]
        try:
            try:
                # A fixed working directory keeps relative model paths and dump
                # locations consistent. check=True rejects failed compilations.
                subprocess.run(command, cwd=base_dir, check=True)
            except FileNotFoundError as error:
                raise RuntimeError("GAMS executable 'gams' was not found on PATH") from error
            # A zero exit status alone is insufficient if no usable dump exists.
            if not dump.is_file() or dump.stat().st_size == 0:
                raise RuntimeError("GAMS completed without creating the preprocessed model")
            # Publish each model under its own name, creating the generated
            # output folder only after compilation has produced a usable dump.
            output_dir = base_dir / "tempMCPs"
            if output_dir.is_symlink():
                raise RuntimeError(f"Extraction output directory must not be a symlink: {output_dir}")
            output_dir.mkdir(exist_ok=True)
            output = output_dir / f"{args.select}.gms"
            if output.exists() and output.samefile(model):
                raise RuntimeError(f"Extraction output would overwrite the source model: {output}")
            # Replace the output only after success. Both paths are on the same
            # filesystem, so readers see the complete old or new model.
            dump.replace(output)
        finally:
            # Restore the original dump on success or failure; otherwise remove
            # any partial dump produced by this attempt.
            if previous_dump.exists() or previous_dump.is_symlink():
                previous_dump.replace(dump)
            elif dump.exists():
                dump.unlink()
    return output


def main(argv=None):
    """Dispatch the command and return its exit status to the command line."""
    args = parse_arguments(argv)

    if args.command == "addProblem":
        try:
            record = add_problem(args.type, args.file, BASE_DIR)
        except (OSError, RuntimeError, ValueError) as error:
            print(f"Cannot add problem: {error}", file=sys.stderr)
            return 1
        print(f"Registered problem '{args.type}/{record['name']}'; file: {BASE_DIR / record['file']}")
        return 0

    if args.command == "addType":
        try:
            folder = add_type(args.type, BASE_DIR)
        except (OSError, ValueError) as error:
            print(f"Cannot add type: {error}", file=sys.stderr)
            return 1
        print(f"Registered type '{args.type}' in problems.json; folder: {folder}")
        return 0

    if args.command == "list":
        # Registration determines which files are problems; do not scan folders.
        try:
            data = load_registry(BASE_DIR)
            if args.type not in data["types"]:
                available = ", ".join(data["types"]) or "none"
                raise ValueError(f"Unknown type '{args.type}'. Registered types: {available}")
        except (OSError, ValueError) as error:
            print(f"Cannot list problems: {error}", file=sys.stderr)
            return 1
        selected = sorted(
            (record for record in data["problems"] if record["type"] == args.type),
            key=lambda record: record["name"],
        )
        for record in selected:
            if (BASE_DIR / record["file"]).is_file():
                print(record["name"])
            else:
                print(
                    f"Warning: registered problem {args.type}/{record['name']} "
                    f"is unavailable; missing model file: {record['file']}",
                    file=sys.stderr,
                )
        return 0

    print_arguments(args)
    try:
        output = extract_problem(args, BASE_DIR)
    except subprocess.CalledProcessError as error:
        # Preserve the compiler's exit status so shell scripts can detect failures.
        print(f"Extraction failed: GAMS exited with status {error.returncode}.", file=sys.stderr)
        return error.returncode
    except (OSError, RuntimeError, ValueError) as error:
        # Report expected input/environment errors without a Python traceback.
        print(f"Extraction failed: {error}", file=sys.stderr)
        return 1
    print(f"Saved extracted model to {output}")
    return 0


if __name__ == "__main__":
    # Importing this module leaves command execution to the caller.
    raise SystemExit(main())
