"""Checks for the standalone MCP/VI extraction entry point."""

from contextlib import redirect_stderr, redirect_stdout
from io import StringIO
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


class ExtractionTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="extract-unit-")
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        for category in ("MCP", "VI"):
            (self.root / category).mkdir()
            (self.root / category / "example.gms").write_text("* A standalone model\n")

    def arguments(self, category="MCP", *options):
        return extraction.parse_arguments(["extract", "--type", category, "--select", "example", *options])

    @staticmethod
    def successful_compile(command, **kwargs):
        dump = Path(kwargs["cwd"]) / (Path(command[1]).stem + ".dmp")
        dump.write_text("* Expanded GAMS source\n")

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
        output = StringIO()
        with patch.object(extraction, "BASE_DIR", self.root), patch.object(
            extraction.subprocess, "run"
        ) as run, redirect_stdout(output):
            result = extraction.main(["list", "--type", "VI"])
        self.assertEqual(result, 0)
        self.assertEqual(output.getvalue().splitlines(), ["aaa", "example"])
        run.assert_not_called()

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
