"""Export continuous LINLib LPs as standalone MCP models with poly.txt writers."""

import argparse
from collections import Counter
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile


HERE = Path(__file__).resolve().parent
SKIP_REASONS = {
    "SKIP_DISCRETE": "contains non-continuous variables",
    "SKIP_QUADRATIC_OBJECTIVE": "contains a quadratic objective",
    "SKIP_QUADRATIC_CONSTRAINTS": "contains quadratic constraints",
    "SKIP_CONES": "contains cone constraints",
}


def mcp_solve_position(source):
    """Find the unique JAMS MCP solve, excluding full-line and onText comments."""
    positions = []
    in_comment = False
    solve = re.compile(r"^[ \t]*solve[ \t]+\w+[ \t]+using[ \t]+mcp[ \t]*;", re.I)
    for line in re.finditer(r"(?m)^[^\r\n]+", source):
        text = line.group().strip()
        if text.lower().startswith("$ontext"):
            in_comment = True
        elif text.lower().startswith("$offtext"):
            in_comment = False
        elif not in_comment and not text.startswith("*") and solve.match(line.group()):
            positions.append(line.start())
    if len(positions) != 1:
        raise ValueError(f"Expected one generated MCP solve statement; found {len(positions)}")
    return positions[0]


def unused_symbol(source, name):
    candidate = name
    suffix = 0
    while re.search(rf"\b{re.escape(candidate)}\b", source, re.I):
        suffix += 1
        candidate = f"{name}{suffix}"
    return candidate


def exported_poly_text(source):
    """JAMS pairs introduced constraint multipliers u<number> with poly rows."""
    position = mcp_solve_position(source)
    model_name = re.match(r"\s*solve\s+(\w+)", source[position:], re.I).group(1)
    model = re.search(rf"\bmodel\s+{re.escape(model_name)}\s*/(.*?)/\s*;", source, re.I | re.S)
    if model is None:
        raise ValueError("Cannot find the generated MCP's model definition")
    entries = [entry.strip() for entry in model.group(1).split(",")]
    pairs = [re.fullmatch(r"([A-Za-z][A-Za-z0-9_]*)\s*\.\s*([xu][0-9]+)", entry, re.I) for entry in entries]
    if not pairs or any(pair is None for pair in pairs):
        bad = [entry for entry, pair in zip(entries, pairs) if pair is None]
        raise ValueError(f"Cannot identify JAMS complementarity pairs: {bad[:2]}")
    return "".join(f"{pair[1]}\n" for pair in pairs if pair[2].lower().startswith("u"))


def embed_poly_writer(source, poly_text):
    """Preserve the JAMS source and insert a matching GAMS writer before solve."""
    rows = [line.strip() for line in poly_text.splitlines() if line.strip()]
    if any(not re.fullmatch(r"[A-Za-z][A-Za-z0-9_]*", row) for row in rows):
        raise ValueError("Expected scalar LINLib/JAMS equation names")
    normalized = [row.lower() for row in rows]
    if len(normalized) != len(set(normalized)):
        raise ValueError("Duplicate polyhedral row names")
    definitions = set(re.findall(r"(?im)^[ \t]*([A-Za-z][A-Za-z0-9_]*)[ \t]*\.\.", source))
    missing = set(normalized) - {name.lower() for name in definitions}
    if missing:
        raise ValueError(f"Polyhedral rows missing from the MCP: {', '.join(sorted(missing)[:5])}")

    position = mcp_solve_position(source)
    if not rows:
        block = "* This instance has no polyhedral rows.\n$onEcho > poly.txt\n$offEcho\n\n"
        return source[:position] + block + source[position:], 0
    output = unused_symbol(source, "linlibPolyFile")
    counter = unused_symbol(source, "linlibPolyRow")
    block = [
        "* Regenerate this instance's polyhedral row information before solving.",
        f"File {output} / 'poly.txt' /;",
        f"{output}.pc = 2;",
    ]
    # Numbering can have gaps after JAMS preprocessing. Compress only truly
    # consecutive runs so no omitted row is accidentally included.
    runs = []
    for row in rows:
        previous = runs[-1][-1] if runs else ""
        if (re.fullmatch(r"e[0-9]+", previous, re.I)
                and row == f"{previous[0]}{int(previous[1:]) + 1}"):
            runs[-1].append(row)
        else:
            runs.append([row])
    if any(len(run) > 1 for run in runs):
        block.append(f"Scalar {counter};")
    block.append(f"put {output};")
    for run in runs:
        if len(run) > 1:
            block.extend([
                f"for ({counter} = {int(run[0][1:])} to {int(run[-1][1:])},",
                f"    put '{run[0][0]}' {counter}:0:0 /;",
                ");",
            ])
        else:
            block.append(f"put '{run[0]}' /;")
    block.extend([f"putclose {output};", "", ""])
    return source[:position] + "\n".join(block) + source[position:], len(rows)


def write_model(target, content):
    """Publish a completed model only after conversion and validation succeed."""
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w", encoding="utf-8", dir=target.parent,
            prefix=f".{target.stem}-", suffix=".tmp", delete=False,
        ) as stream:
            temporary = Path(stream.name)
            stream.write(content)
        temporary.replace(target)
    finally:
        if temporary is not None and temporary.exists():
            temporary.unlink()


def verify_poly_writer(source, expected, work, gams):
    """Execute a temporary copy with its final solve disabled; check poly.txt."""
    position = mcp_solve_position(source)
    check = work / "verify_poly.gms"
    check.write_text(source[:position] + "* " + source[position:])
    poly = work / "poly.txt"
    if poly.exists():
        poly.unlink()
    with (work / "verify_driver.log").open("w") as driver:
        process = subprocess.run(
            [gams, str(check), "lo=2"], cwd=work,
            stdout=driver, stderr=subprocess.STDOUT,
        )
    if process.returncode:
        raise ValueError(f"Standalone poly writer check failed with GAMS status {process.returncode}")
    actual = poly.read_text().splitlines() if poly.exists() else []
    wanted = expected.splitlines()
    if not poly.exists() or actual != wanted:
        first = next((index for index, (left, right) in enumerate(zip(actual, wanted)) if left != right), min(len(actual), len(wanted)))
        raise ValueError(
            f"Poly writer mismatch at line {first + 1}: "
            f"expected {wanted[first:first + 1]}, got {actual[first:first + 1]} "
            f"({len(wanted)} expected rows, {len(actual)} actual rows)"
        )


def convert_instance(instance, args):
    target = args.output_dir / f"{instance.stem}.gms"
    result = {"instance": instance.stem, "status": "failed"}
    if target.exists() and not args.overwrite:
        return {**result, "status": "existing", "reason": "output already exists"}

    with tempfile.TemporaryDirectory(prefix=f"linlib-{instance.stem}-") as directory:
        work = Path(directory)
        command = [
            args.gams, str(HERE / "generate_mcp_for_lp.gms"),
            f"--iname={instance}", "--quad=0", "--batchStatus=conversion.status", "lo=2",
        ]
        with (work / "driver.log").open("w") as driver:
            process = subprocess.run(command, cwd=work, stdout=driver, stderr=subprocess.STDOUT)
        status_file = work / "conversion.status"
        status = status_file.read_text().strip() if status_file.exists() else ""
        model = work / "mcp_formulation.gms"
        exporter = "jams"
        if process.returncode == 0 and status == "LP" and not model.exists():
            exporter = "direct"
            with (work / "fallback_driver.log").open("w") as driver:
                process = subprocess.run(
                    command + [f"--directExport={HERE / 'export_lp_mcp.gms'}"],
                    cwd=work, stdout=driver, stderr=subprocess.STDOUT,
                )
        try:
            if process.returncode:
                raise ValueError(f"GAMS exited with status {process.returncode}")
            if status in SKIP_REASONS:
                return {**result, "status": "skipped", "reason": SKIP_REASONS[status]}
            if status != "LP":
                raise ValueError("Converter did not confirm a continuous LP")
            if not model.is_file():
                raise ValueError("Converter did not produce mcp_formulation.gms")
            original = model.read_text()
            poly_text = exported_poly_text(original)
            source, row_count = embed_poly_writer(original, poly_text)
            if args.verify:
                verify_poly_writer(source, poly_text, work, args.gams)
            write_model(target, source)
            old_log = args.log_dir / f"{instance.stem}.log"
            if old_log.exists():
                old_log.unlink()
            return {
                **result, "status": "generated", "polyhedral_rows": row_count,
                "exporter": exporter, "verified_poly_writer": args.verify,
            }
        except (OSError, ValueError) as error:
            args.log_dir.mkdir(parents=True, exist_ok=True)
            log_path = args.log_dir / f"{instance.stem}.log"
            log = "\n".join(path.read_text(errors="replace") for path in sorted(work.glob("*.log")))
            log_path.write_text(log + f"\nExport error: {error}\n")
            return {
                **result, "reason": str(error), "log": str(log_path),
                "fatal": process.returncode == 7,
            }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--instances-dir", type=Path, default=HERE / "instances")
    parser.add_argument("--output-dir", type=Path, default=HERE.parent)
    parser.add_argument("--select", nargs="+", metavar="INSTANCE", help="Export only these instance names")
    parser.add_argument("--overwrite", action="store_true", help="Replace existing output models")
    parser.add_argument("--verify", action="store_true", help="Run each exported model with its solve disabled and check poly.txt")
    parser.add_argument("--gams", default="gams", help="GAMS executable")
    parser.add_argument("--report", type=Path, default=HERE / "generation_report.json")
    parser.add_argument("--log-dir", type=Path, default=HERE / "generation_logs")
    args = parser.parse_args()
    args.instances_dir = args.instances_dir.resolve()
    args.output_dir = args.output_dir.resolve()
    args.log_dir = args.log_dir.resolve()
    args.report = args.report.resolve()
    args.gams = shutil.which(args.gams)
    if args.gams is None:
        parser.error("GAMS executable not found")
    if not args.instances_dir.is_dir():
        parser.error(f"Instance directory not found: {args.instances_dir}")
    instances = sorted(args.instances_dir.glob("*.gdx"))
    if args.select:
        selected = {Path(name).stem for name in args.select}
        missing = selected - {path.stem for path in instances}
        if missing:
            parser.error(f"Unknown instances: {', '.join(sorted(missing))}")
        instances = [path for path in instances if path.stem in selected]
    if not instances:
        parser.error("No GDX instances found")
    args.output_dir.mkdir(parents=True, exist_ok=True)
    results = []
    for index, instance in enumerate(instances, 1):
        result = convert_instance(instance, args)
        results.append(result)
        detail = result.get("reason", f"{result.get('polyhedral_rows', 0)} polyhedral rows")
        print(f"[{index}/{len(instances)}] {result['status'].upper()} {instance.stem}: {detail}", flush=True)
        if result.get("fatal"):
            print("Stopping after a GAMS license error.", flush=True)
            break
    args.report.parent.mkdir(parents=True, exist_ok=True)
    counts = dict(Counter(result["status"] for result in results))
    args.report.write_text(json.dumps({"counts": counts, "instances": results}, indent=2) + "\n")
    print(f"Summary: {counts}\nReport: {args.report}", flush=True)
    return int(bool(counts.get("failed")))


if __name__ == "__main__":
    raise SystemExit(main())
