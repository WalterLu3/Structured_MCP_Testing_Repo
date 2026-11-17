"""Register, list, or extract models individually or from a names-only list.

The problem catalog is stored in problems.json beside this script.
Each type has a folder beside this script. Extraction copies the selected
source unchanged into tempMCPs/. Parameter defaults belong in the GAMS
source; users can override them when running GAMS separately.
"""

import argparse
import json
import re
import shutil
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
        "extract", help="Copy a problem's GAMS source into tempMCPs/."
    )
    batch_parser = subparsers.add_parser(
        "extractList", help="Extract registered problems named in a text file."
    )
    batch_parser.add_argument(
        "--file", required=True, type=Path,
        help="Text file containing one registered problem name per line.",
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

    for command, help_text in (
        ("updateProblem", "Refresh a registered model's runtime option metadata."),
        ("listOpt", "List runtime options and check their registered metadata."),
    ):
        option_parser = subparsers.add_parser(command, help=help_text)
        option_parser.add_argument("--type", required=True, type=parse_type_name)
        option_parser.add_argument("--select", required=True, help="Registered model name without .gms.")

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

    return parser.parse_args(argv)


def print_arguments(args):
    """Show the selected command and source before copying."""
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
        options = record.get("options", [])
        if (not isinstance(options, list) or any(
                not isinstance(option, str) or not re.fullmatch(r"[A-Za-z][A-Za-z0-9_]*", option)
                for option in options)):
            raise ValueError(f"Problem record {index}: options must be an array of option names without '--'")
        if len({option.casefold() for option in options}) != len(options):
            raise ValueError(f"Problem record {index}: duplicate option names")
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


def active_gams_lines(source):
    """Stream source, skipping common comments and literal echo blocks.

    This supports the repository convention, not arbitrary GAMS preprocessing.
    Includes are not expanded and conditional branches are not evaluated.
    """
    block = None
    c_comment = False
    with Path(source).open(encoding="utf-8-sig") as stream:
        for number, raw in enumerate(stream, 1):
            if not block and not c_comment and "$" not in raw and "%" not in raw and "/*" not in raw:
                continue  # Large exported models mostly contain ordinary equations.
            stripped = raw.lstrip()
            if block:
                if re.match(rf"\${block}\b", stripped, re.I):
                    block = None
                continue
            if not c_comment and stripped.startswith("*"):
                continue
            # Preserve quoted strings: percent references within them are used
            # by GAMS too, while comment delimiters inside them are literal.
            if not c_comment and "/*" not in raw:
                line = raw
            else:
                line = []
                quote = None
                index = 0
                while index < len(raw):
                    pair = raw[index:index + 2]
                    char = raw[index]
                    if c_comment:
                        if pair == "*/":
                            c_comment = False
                            line.append(" ")
                            index += 2
                            continue
                    elif quote:
                        line.append(char)
                        if char == quote:
                            if index + 1 < len(raw) and raw[index + 1] == quote:
                                line.append(quote)
                                index += 2
                                continue
                            quote = None
                    elif pair == "/*":
                        c_comment = True
                        index += 2
                        continue
                    else:
                        line.append(char)
                        if char in "\"'":
                            quote = char
                    index += 1
                line = "".join(line)
            if re.match(r"\s*\$ontext\b", line, re.I):
                block = "offtext"
                continue
            if re.match(r"\s*\$onecho(?:v)?\b", line, re.I):
                block = "offecho"
                continue
            if re.fullmatch(r"\s*\$exit\s*", line, re.I):
                break
            yield number, line
    if block or c_comment:
        raise ValueError(f"{source}: unterminated comment or echo block")


def detect_options(source):
    """Find referenced options declared using a conditional default.

    Supported form: $if not set NAME $set NAME DEFAULT (case insensitive).
    A $setglobal assignment is also supported with the same 'not set' guard.
    """
    default = re.compile(
        r"^\s*\$if\s+not\s+set\s+([A-Za-z][A-Za-z0-9_]*)\s+"
        r"\$set(?:global)?\s+([A-Za-z][A-Za-z0-9_]*)(?:\s+(.*?))?\s*$", re.I,
    )
    declared, referenced = {}, set()
    for number, line in active_gams_lines(source):
        match = default.match(line)
        if match:
            checked, assigned, value = match.groups()
            if checked.casefold() != assigned.casefold():
                raise ValueError(f"{source}:{number}: default checks '{checked}' but sets '{assigned}'")
            if value is None or not value.strip():
                raise ValueError(f"{source}:{number}: option '{assigned}' needs a nonempty default")
            declared.setdefault(assigned.casefold(), assigned)
            line = value
        referenced.update(name.casefold() for name in re.findall(r"%([A-Za-z][A-Za-z0-9_]*)%", line))
    unused = [name for key, name in declared.items() if key not in referenced]
    if unused:
        raise ValueError(f"{source}: options declared but not referenced: {', '.join(unused)}")
    return sorted(declared.values(), key=str.casefold)


def registered_problem(data, category, name):
    """Resolve an exact registry entry before using its validated source path."""
    for record in data["problems"]:
        if record["type"] == category and record["name"] == name:
            return record
    raise ValueError(f"Problem '{category}/{name}' is not registered")


def update_problem(category, name, base_dir):
    """Refresh only one model's derived options, publishing the registry atomically."""
    data = load_registry(base_dir)
    record = registered_problem(data, category, name)
    record["options"] = detect_options(base_dir / record["file"])
    save_registry(base_dir, data)
    return record


def list_options(category, name, base_dir):
    """Display source-derived options, warning about stale metadata without writing."""
    data = load_registry(base_dir)
    record = registered_problem(data, category, name)
    options = detect_options(base_dir / record["file"])
    print(f"Options for {category}/{name}: {', '.join(options) if options else '(none)'}")
    if options:
        flags = " ".join(f"--{option}=VALUE" for option in options)
        print(f"Example (replace VALUE with the desired value): gams {name}.gms {flags}")
    stale = ("options" not in record or
             {option.casefold() for option in record["options"]} != {option.casefold() for option in options})
    if stale:
        print(
            f"Warning: option metadata for {category}/{name} is stale. Refresh it with:\n"
            f"  python3 extractProblem.py updateProblem --type {category} --select {name}",
            file=sys.stderr,
        )
    return 1 if stale else 0


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

    record = {"name": name, "type": category, "file": f"{category}/{name}.gms",
              "options": detect_options(source)}
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
    """Copy a GAMS source unchanged to tempMCPs/<selected name>.gms."""
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

    output_dir = base_dir / "tempMCPs"
    if output_dir.is_symlink():
        raise RuntimeError(f"Extraction output directory must not be a symlink: {output_dir}")
    output_dir.mkdir(exist_ok=True)
    output = output_dir / f"{args.select}.gms"
    if output.exists() and output.samefile(model):
        raise RuntimeError(f"Extraction output would overwrite the source model: {output}")

    # Stream large models and publish only a complete copy. A failed copy leaves
    # any previous output intact, and source bytes (including defaults) are kept.
    temporary = None
    try:
        with model.open("rb") as reader, tempfile.NamedTemporaryFile(
            dir=output_dir, prefix=f".{args.select}-", suffix=".gms", delete=False,
        ) as writer:
            temporary = Path(writer.name)
            shutil.copyfileobj(reader, writer)
        temporary.replace(output)
    finally:
        if temporary is not None and temporary.exists():
            temporary.unlink()
    return output


def extract_list(source_file, base_dir):
    """Resolve names across registered types and continue after individual errors."""
    records = load_problem_records(base_dir)
    # Resolve the input relative to the caller, while outputs stay in the repo.
    lines = source_file.expanduser().read_text(encoding="utf-8-sig").splitlines()
    by_name = {}
    for record in records:
        by_name.setdefault(record["name"], []).append(record)

    extracted = skipped = failed = 0
    seen = set()
    for number, line in enumerate(lines, 1):
        name = line.split("#", 1)[0].strip()
        if not name:
            continue
        context = f"{source_file}:{number}: {name}"
        if name in seen:
            print(f"Warning: {context}: duplicate name; skipping.", file=sys.stderr)
            skipped += 1
            continue
        seen.add(name)
        matches = by_name.get(name, [])
        if len(matches) != 1:
            reason = ("not registered" if not matches else
                      "registered under multiple types: "
                      + ", ".join(record["type"] for record in matches))
            print(f"Warning: {context}: {reason}; skipping.", file=sys.stderr)
            failed += 1
            continue
        record = matches[0]
        # Individual and batch extraction both copy the source unchanged.
        args = parse_arguments([
            "extract", "--type", record["type"], f"--select={name}",
        ])
        try:
            output = extract_problem(args, base_dir)
        except (OSError, RuntimeError, ValueError) as error:
            print(f"Extraction failed: {context}: {error}", file=sys.stderr)
            failed += 1
        else:
            print(f"Saved extracted model to {output}")
            extracted += 1
    print(f"Batch complete: {extracted} extracted, {skipped} skipped, {failed} failed.")
    return 1 if failed else 0


def main(argv=None):
    """Dispatch the command and return its exit status to the command line."""
    args = parse_arguments(argv)

    if args.command in {"updateProblem", "listOpt"}:
        try:
            if args.command == "listOpt":
                return list_options(args.type, args.select, BASE_DIR)
            record = update_problem(args.type, args.select, BASE_DIR)
        except (OSError, UnicodeError, RuntimeError, ValueError) as error:
            print(f"Cannot {args.command}: {error}", file=sys.stderr)
            return 1
        print(f"Updated options for {args.type}/{args.select}: {', '.join(record['options']) or '(none)'}")
        return 0

    if args.command == "extractList":
        try:
            return extract_list(args.file, BASE_DIR)
        except (OSError, UnicodeError, ValueError) as error:
            print(f"Cannot extract problem list: {error}", file=sys.stderr)
            return 1

    if args.command == "addProblem":
        try:
            record = add_problem(args.type, args.file, BASE_DIR)
        except (OSError, UnicodeError, RuntimeError, ValueError) as error:
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
    except (OSError, RuntimeError, ValueError) as error:
        # Report expected input/environment errors without a Python traceback.
        print(f"Extraction failed: {error}", file=sys.stderr)
        return 1
    print(f"Saved extracted model to {output}")
    return 0


if __name__ == "__main__":
    # Importing this module leaves command execution to the caller.
    raise SystemExit(main())
