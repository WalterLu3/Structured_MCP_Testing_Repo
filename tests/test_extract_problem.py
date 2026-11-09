"""Checks for the standalone MCP/VI extraction entry point."""

from contextlib import redirect_stderr, redirect_stdout
from io import StringIO
import json
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch


ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
import extractProblem as extraction


RUN_GAMS_TESTS = "--gams-tests" in sys.argv
if RUN_GAMS_TESTS:
    sys.argv.remove("--gams-tests")


class ExtractionFixture(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="extract-unit-")
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        for category in ("MCP", "VI"):
            (self.root / category).mkdir()
            (self.root / category / "example.gms").write_text("* A standalone model\n")
        self.write_records([
            {"name": "example", "type": category, "file": f"{category}/example.gms"}
            for category in ("MCP", "VI")
        ])

    def write_records(self, records):
        (self.root / "problems.json").write_text(json.dumps({"problems": records}))

    def arguments(self, category="MCP", *options):
        return extraction.parse_arguments(["extract", "--type", category, "--select", "example", *options])

    @staticmethod
    def successful_compile(command, **kwargs):
        dump = Path(kwargs["cwd"]) / (Path(command[1]).stem + ".dmp")
        dump.write_text("* Expanded GAMS source\n")


class ExtractionTests(ExtractionFixture):
    def test_compiles_each_category_directly_without_subfolder_scripts(self):
        for category in ("MCP", "VI"):
            with self.subTest(category=category), patch.object(
                extraction.subprocess, "run", side_effect=self.successful_compile
            ) as run:
                output = extraction.extract_problem(self.arguments(category), self.root)
                command = run.call_args.args[0]
                self.assertEqual(command[:4], ["gams", str(self.root / category / "example.gms"), "action=c", "dumpOpt=21"])
                self.assertEqual(run.call_args.kwargs, {"cwd": self.root, "check": True})
                self.assertEqual(output, self.root / "tempMCP.gms")
                self.assertEqual(output.read_text(), "* Expanded GAMS source\n")
                self.assertFalse(list(self.root.glob(".extractProblem-*")))

    def test_forwards_supplied_parameters_and_preserves_gams_flag_names(self):
        args = self.arguments("VI", "--dimension", "7", "--quad", "0", "--lambda", "0.5", "--randomSeed", "3")
        with patch.object(extraction.subprocess, "run", side_effect=self.successful_compile) as run:
            extraction.extract_problem(args, self.root)
        flags = {value for value in run.call_args.args[0] if value.startswith("--")}
        self.assertEqual(flags, {"--dimension=7", "--quad=0.0", "--lambda=0.5", "--randomSeed=3"})

    def test_omits_unspecified_flags_so_model_defaults_apply(self):
        with patch.object(extraction.subprocess, "run", side_effect=self.successful_compile) as run:
            extraction.extract_problem(self.arguments(), self.root)
        self.assertFalse(any(value.startswith("--") for value in run.call_args.args[0]))

    def test_failed_compile_preserves_output_and_does_not_use_stale_dump(self):
        output = self.root / "tempMCP.gms"
        output.write_text("previous model")
        stale = self.root / "example.dmp"
        stale.write_text("old dump")

        def fail(command, **kwargs):
            self.successful_compile(command, **kwargs)
            raise subprocess.CalledProcessError(2, command)

        with patch.object(extraction.subprocess, "run", side_effect=fail):
            with self.assertRaises(subprocess.CalledProcessError):
                extraction.extract_problem(self.arguments(), self.root)
        self.assertEqual(output.read_text(), "previous model")
        self.assertEqual(stale.read_text(), "old dump")
        self.assertFalse(list(self.root.glob(".extractProblem-*")))

    def test_successful_compile_preserves_a_preexisting_dump(self):
        stale = self.root / "example.dmp"
        stale.write_text("old dump")
        with patch.object(extraction.subprocess, "run", side_effect=self.successful_compile):
            output = extraction.extract_problem(self.arguments(), self.root)
        self.assertEqual(output.read_text(), "* Expanded GAMS source\n")
        self.assertEqual(stale.read_text(), "old dump")

    def test_does_not_move_a_directory_that_has_the_dump_filename(self):
        directory = self.root / "example.dmp"
        directory.mkdir()
        (directory / "keep.txt").write_text("keep this directory")
        with patch.object(extraction.subprocess, "run") as run:
            with self.assertRaisesRegex(RuntimeError, "not a file"):
                extraction.extract_problem(self.arguments(), self.root)
        run.assert_not_called()
        self.assertEqual((directory / "keep.txt").read_text(), "keep this directory")

    def test_success_without_a_dump_does_not_replace_existing_output(self):
        output = self.root / "tempMCP.gms"
        output.write_text("previous model")
        with patch.object(extraction.subprocess, "run"):
            with self.assertRaisesRegex(RuntimeError, "without creating"):
                extraction.extract_problem(self.arguments(), self.root)
        self.assertEqual(output.read_text(), "previous model")

    def test_missing_model_does_not_fall_back_to_gdx_conversion(self):
        (self.root / "VI" / "example.gms").unlink()
        dataset = self.root / "VI" / "LINLib" / "instances" / "example.gdx"
        dataset.parent.mkdir(parents=True)
        dataset.write_text("a dataset is not a standalone model")
        with patch.object(extraction.subprocess, "run") as run:
            with self.assertRaisesRegex(FileNotFoundError, "list --type VI"):
                extraction.extract_problem(self.arguments("VI"), self.root)
        run.assert_not_called()

    def test_rejects_model_names_outside_the_selected_folder(self):
        for name in ("../example", "..", "sub/example", "sub\\example", ""):
            args = self.arguments()
            args.select = name
            with self.subTest(name=name), patch.object(extraction.subprocess, "run") as run:
                with self.assertRaises(ValueError):
                    extraction.extract_problem(args, self.root)
                run.assert_not_called()

    def test_list_is_sorted_and_does_not_require_gams(self):
        (self.root / "VI" / "aaa.gms").write_text("* Another model\n")
        (self.root / "VI" / "helper.py").write_text("")
        (self.root / "VI" / "directory.gms").mkdir()
        self.write_records([
            {"name": "example", "type": "VI", "file": "VI/example.gms"},
            {"name": "aaa", "type": "VI", "file": "VI/aaa.gms"},
            {"name": "example", "type": "MCP", "file": "MCP/example.gms"},
        ])
        output = StringIO()
        with patch.object(extraction, "BASE_DIR", self.root), patch.object(
            extraction.subprocess, "run"
        ) as run, redirect_stdout(output):
            result = extraction.main(["list", "--type", "VI"])
        self.assertEqual(result, 0)
        self.assertEqual(output.getvalue().splitlines(), ["aaa", "example"])
        run.assert_not_called()

    def test_unregistered_model_is_not_listed(self):
        (self.root / "VI" / "unregistered.gms").write_text("* Not in the catalog\n")
        output = StringIO()
        with patch.object(extraction, "BASE_DIR", self.root), redirect_stdout(output):
            code = extraction.main(["list", "--type", "VI"])
        self.assertEqual(code, 0)
        self.assertEqual(output.getvalue().splitlines(), ["example"])

    def test_missing_registered_model_warns_without_invalidating_catalog(self):
        (self.root / "VI" / "example.gms").unlink()
        output, error = StringIO(), StringIO()
        with patch.object(extraction, "BASE_DIR", self.root), patch.object(
            extraction.subprocess, "run"
        ) as run, redirect_stdout(output), redirect_stderr(error):
            code = extraction.main(["list", "--type", "VI"])
        self.assertEqual(code, 0)
        self.assertEqual(output.getvalue(), "")
        self.assertIn("missing model file: VI/example.gms", error.getvalue())
        self.assertEqual(len(extraction.load_problem_records(self.root)), 2)
        run.assert_not_called()

    def test_missing_other_category_does_not_affect_requested_list(self):
        (self.root / "MCP" / "example.gms").unlink()
        output, error = StringIO(), StringIO()
        with patch.object(extraction, "BASE_DIR", self.root), redirect_stdout(output), redirect_stderr(error):
            code = extraction.main(["list", "--type", "VI"])
        self.assertEqual(code, 0)
        self.assertEqual(output.getvalue().splitlines(), ["example"])
        self.assertEqual(error.getvalue(), "")

    def test_missing_registry_reports_an_error_instead_of_scanning_folders(self):
        (self.root / "problems.json").unlink()
        output, error = StringIO(), StringIO()
        with patch.object(extraction, "BASE_DIR", self.root), redirect_stdout(output), redirect_stderr(error):
            code = extraction.main(["list", "--type", "VI"])
        self.assertEqual(code, 1)
        self.assertEqual(output.getvalue(), "")
        self.assertIn("problems.json", error.getvalue())

    def test_invalid_json_reports_a_readable_error(self):
        (self.root / "problems.json").write_text('{"problems": [')
        error = StringIO()
        with patch.object(extraction, "BASE_DIR", self.root), redirect_stderr(error):
            code = extraction.main(["list", "--type", "MCP"])
        self.assertEqual(code, 1)
        self.assertIn("Invalid JSON", error.getvalue())

    def test_rejects_invalid_records_and_paths(self):
        valid = {"name": "example", "type": "VI", "file": "VI/example.gms"}
        for record in (
            None, {}, {**valid, "name": 3}, {**valid, "type": "LP"},
            {**valid, "name": "../example"}, {**valid, "file": "../example.gms"},
            {**valid, "file": "MCP/example.gms"}, {**valid, "file": "/VI/example.gms"},
        ):
            with self.subTest(record=record):
                self.write_records([record])
                with self.assertRaises(ValueError):
                    extraction.load_problem_records(self.root)
        for data in ([], {}, {"problems": {}}):
            with self.subTest(data=data):
                (self.root / "problems.json").write_text(json.dumps(data))
                with self.assertRaises(ValueError):
                    extraction.load_problem_records(self.root)

    def test_rejects_duplicate_names_within_a_category(self):
        record = {"name": "example", "type": "VI", "file": "VI/example.gms"}
        self.write_records([record, record])
        with self.assertRaisesRegex(ValueError, "Duplicate problem registration: VI/example"):
            extraction.load_problem_records(self.root)

    def test_extraction_still_works_without_the_listing_registry(self):
        (self.root / "problems.json").unlink()
        with patch.object(extraction, "BASE_DIR", self.root), patch.object(
            extraction.subprocess, "run", side_effect=self.successful_compile
        ), redirect_stdout(StringIO()):
            code = extraction.main(["extract", "--type", "MCP", "--select", "example"])
        self.assertEqual(code, 0)
        self.assertTrue((self.root / "tempMCP.gms").is_file())

    def test_cli_reports_compiler_failure_without_a_python_traceback(self):
        error = StringIO()
        with patch.object(extraction, "BASE_DIR", self.root), patch.object(
            extraction.subprocess, "run", side_effect=subprocess.CalledProcessError(7, ["gams"])
        ), redirect_stdout(StringIO()), redirect_stderr(error):
            code = extraction.main(["extract", "--type", "MCP", "--select", "example"])
        self.assertEqual(code, 7)
        self.assertIn("GAMS exited with status 7", error.getvalue())

    def test_cli_reports_missing_gams(self):
        error = StringIO()
        with patch.object(extraction, "BASE_DIR", self.root), patch.object(
            extraction.subprocess, "run", side_effect=FileNotFoundError("gams")
        ), redirect_stdout(StringIO()), redirect_stderr(error):
            code = extraction.main(["extract", "--type", "MCP", "--select", "example"])
        self.assertEqual(code, 1)
        self.assertIn("not found on PATH", error.getvalue())


class TypeRegistrationTests(ExtractionFixture):
    def test_add_type_creates_folder_and_preserves_existing_records(self):
        before = extraction.load_problem_records(self.root)
        output = StringIO()
        with patch.object(extraction, "BASE_DIR", self.root), patch.object(
            extraction.subprocess, "run"
        ) as run, redirect_stdout(output):
            code = extraction.main(["addType", "--type", "NCP"])
        self.assertEqual(code, 0)
        self.assertIn("Registered type 'NCP'", output.getvalue())
        self.assertTrue((self.root / "NCP" / ".gitkeep").is_file())
        data = extraction.load_registry(self.root)
        self.assertEqual(data["types"], ["MCP", "VI", "NCP"])
        self.assertEqual(data["problems"], before)
        run.assert_not_called()

    def test_new_type_can_be_listed_before_it_has_problems(self):
        extraction.add_type("NCP", self.root)
        output, error = StringIO(), StringIO()
        with patch.object(extraction, "BASE_DIR", self.root), redirect_stdout(output), redirect_stderr(error):
            code = extraction.main(["list", "--type", "NCP"])
        self.assertEqual(code, 0)
        self.assertEqual(output.getvalue(), "")
        self.assertEqual(error.getvalue(), "")

    def test_custom_type_supports_registered_listing_and_direct_extraction(self):
        extraction.add_type("NCP", self.root)
        (self.root / "NCP" / "example.gms").write_text("* A custom problem\n")
        data = extraction.load_registry(self.root)
        data["problems"].append({"name": "example", "type": "NCP", "file": "NCP/example.gms"})
        extraction.save_registry(self.root, data)
        output = StringIO()
        with patch.object(extraction, "BASE_DIR", self.root), redirect_stdout(output):
            code = extraction.main(["list", "--type", "NCP"])
        self.assertEqual(code, 0)
        self.assertEqual(output.getvalue().splitlines(), ["example"])
        with patch.object(extraction.subprocess, "run", side_effect=self.successful_compile) as run:
            output_path = extraction.extract_problem(self.arguments("NCP"), self.root)
        self.assertEqual(output_path.read_text(), "* Expanded GAMS source\n")
        self.assertEqual(run.call_args.args[0][1], str(self.root / "NCP" / "example.gms"))

    def test_existing_folder_and_contents_are_preserved(self):
        folder = self.root / "NCP"
        folder.mkdir()
        (folder / "keep.gms").write_text("user model")
        (folder / ".gitkeep").write_text("existing marker")
        extraction.add_type("NCP", self.root)
        self.assertEqual((folder / "keep.gms").read_text(), "user model")
        self.assertEqual((folder / ".gitkeep").read_text(), "existing marker")

    def test_duplicate_types_and_case_variants_do_not_change_registry(self):
        before = (self.root / "problems.json").read_bytes()
        for category in ("MCP", "mcp"):
            with self.subTest(category=category), self.assertRaisesRegex(ValueError, "already registered"):
                extraction.add_type(category, self.root)
        self.assertEqual((self.root / "problems.json").read_bytes(), before)
        self.assertFalse((self.root / "MCP" / ".gitkeep").exists())

    def test_folder_case_must_match_for_portable_registrations(self):
        (self.root / "ncp").mkdir()
        with self.assertRaisesRegex(ValueError, "exact spelling"):
            extraction.add_type("NCP", self.root)

    def test_invalid_names_are_rejected_before_writing(self):
        before = (self.root / "problems.json").read_bytes()
        for category in ("../NCP", "NCP/new", "NCP\\new", ".git", "NCP space", "", "1NCP"):
            with self.subTest(category=category), self.assertRaises(ValueError):
                extraction.add_type(category, self.root)
        self.assertEqual((self.root / "problems.json").read_bytes(), before)

    def test_cli_rejects_type_paths_for_all_commands(self):
        for command in ("addType", "list", "extract"):
            options = [command, "--type", "../outside"]
            if command == "extract":
                options.extend(["--select", "example"])
            with self.subTest(command=command), redirect_stderr(StringIO()), self.assertRaises(SystemExit):
                extraction.parse_arguments(options)

    def test_existing_file_cannot_become_a_type_folder(self):
        (self.root / "NCP").write_text("keep this file")
        with self.assertRaisesRegex(ValueError, "real directory"):
            extraction.add_type("NCP", self.root)
        self.assertEqual((self.root / "NCP").read_text(), "keep this file")

    def test_failed_save_rolls_back_only_new_files(self):
        before = (self.root / "problems.json").read_bytes()
        for existing in (False, True):
            category = "Existing" if existing else "New"
            folder = self.root / category
            if existing:
                folder.mkdir()
                (folder / "keep.gms").write_text("user model")
            with self.subTest(existing=existing), patch.object(
                extraction, "save_registry", side_effect=OSError("write failed")
            ), self.assertRaises(OSError):
                extraction.add_type(category, self.root)
            self.assertEqual((self.root / "problems.json").read_bytes(), before)
            if existing:
                self.assertEqual((folder / "keep.gms").read_text(), "user model")
                self.assertFalse((folder / ".gitkeep").exists())
            else:
                self.assertFalse(folder.exists())

    def test_atomic_save_preserves_registry_when_replace_fails(self):
        before = (self.root / "problems.json").read_bytes()
        data = extraction.load_registry(self.root)
        data["types"].append("NCP")
        with patch.object(Path, "replace", side_effect=OSError("replace failed")), self.assertRaises(OSError):
            extraction.save_registry(self.root, data)
        self.assertEqual((self.root / "problems.json").read_bytes(), before)
        self.assertFalse(list(self.root.glob(".problems-*.json")))

    def test_unknown_type_is_different_from_an_empty_registered_type(self):
        error = StringIO()
        with patch.object(extraction, "BASE_DIR", self.root), redirect_stderr(error):
            code = extraction.main(["list", "--type", "NCP"])
        self.assertEqual(code, 1)
        self.assertIn("Unknown type 'NCP'", error.getvalue())

    def test_registry_rejects_invalid_or_duplicate_type_declarations(self):
        data = extraction.load_registry(self.root)
        for categories in ("MCP", ["MCP", "VI", "mcp"], ["../outside"], [3], []):
            with self.subTest(categories=categories):
                (self.root / "problems.json").write_text(json.dumps({**data, "types": categories}))
                with self.assertRaises(ValueError):
                    extraction.load_registry(self.root)


@unittest.skipUnless(RUN_GAMS_TESTS, "Enable GAMS integration checks with --gams-tests")
class GamsExtractionTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="extract-gams-")
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name) / "repo with spaces"
        self.caller = Path(self.directory.name) / "caller"
        self.root.mkdir()
        self.caller.mkdir()
        (self.root / "MCP").mkdir()
        (self.root / "VI").mkdir()
        shutil.copy2(ROOT / "extractProblem.py", self.root / "extractProblem.py")

    def extract(self, category, name, *options):
        result = subprocess.run(
            [sys.executable, str(self.root / "extractProblem.py"), "extract", "--type", category, "--select", name, *options],
            cwd=self.caller, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        )
        self.assertEqual(result.returncode, 0, result.stdout[-3000:])
        self.assertFalse((self.caller / "tempMCP.gms").exists())
        return (self.root / "tempMCP.gms").read_text()

    def test_expands_parameters_and_defaults_without_executing_the_model(self):
        model = self.root / "MCP" / "toy.gms"
        model.write_text("""$if not setglobal dimension $setglobal dimension 2
set i /1*%dimension%/;
positive variable x(i);
equation f(i);
f(i).. x(i) - 1 =g= 0;
model m /f.x/;
file sentinel /'executed.txt'/;
putclose sentinel 'The model was executed';
solve m using mcp;
""")
        source = self.extract("MCP", "toy", "--dimension", "4")
        self.assertRegex(source, r"1\s*\*\s*4")
        self.assertFalse((self.root / "executed.txt").exists())
        source = self.extract("MCP", "toy")
        self.assertRegex(source, r"1\s*\*\s*2")
        self.assertFalse((self.root / "executed.txt").exists())

        previous = (self.root / "tempMCP.gms").read_bytes()
        model.write_text("not a valid GAMS model;\n")
        result = subprocess.run(
            [sys.executable, str(self.root / "extractProblem.py"), "extract", "--type", "MCP", "--select", "toy"],
            cwd=self.caller, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual((self.root / "tempMCP.gms").read_bytes(), previous)

    def test_extracted_lp_retains_its_standalone_poly_writer(self):
        shutil.copy2(ROOT / "VI" / "agg.gms", self.root / "VI" / "agg.gms")
        source = self.extract("VI", "agg")
        check, solves = re.subn(r"(?im)^([ \t]*solve[^\n]+;)[ \t]*$", r"* \1", source)
        self.assertEqual(solves, 1)
        check_path = self.root / "check_poly.gms"
        check_path.write_text(check)
        result = subprocess.run(
            ["gams", str(check_path), "lo=2"], cwd=self.root,
            text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        )
        log = self.root / "check_poly.log"
        self.assertEqual(result.returncode, 0, result.stdout + (log.read_text()[-2000:] if log.exists() else ""))
        self.assertEqual((self.root / "poly.txt").read_text().splitlines(), [f"e{i}" for i in range(164, 652)])


if __name__ == "__main__":
    unittest.main()
