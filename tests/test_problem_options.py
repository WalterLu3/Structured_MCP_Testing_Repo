"""Checks for source-derived runtime option metadata and its CLI lifecycle."""

from contextlib import redirect_stderr, redirect_stdout
from io import StringIO
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
import extractProblem as extraction


class ProblemOptionTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory(prefix="problem-options-")
        self.addCleanup(directory.cleanup)
        self.root = Path(directory.name)
        (self.root / "MCP").mkdir()
        self.source = self.root / "MCP" / "example.gms"
        self.source.write_text("$if not set dimension $set dimension 2\nset i /1*%dimension%/;\n")
        self.registry = self.root / "problems.json"
        self.record = {"name": "example", "type": "MCP", "file": "MCP/example.gms", "options": ["dimension"]}
        self.save([self.record])

    def save(self, records):
        self.registry.write_text(json.dumps({"types": ["MCP"], "problems": records}))

    def cli(self, command):
        output, error = StringIO(), StringIO()
        with patch.object(extraction, "BASE_DIR", self.root), redirect_stdout(output), redirect_stderr(error):
            code = extraction.main([command, "--type", "MCP", "--select", "example"])
        return code, output.getvalue(), error.getvalue()

    def test_detects_defaults_and_ignores_internal_variables_and_comments(self):
        self.source.write_text("""* $if not set fake $set fake 1
$ontext
$if not set hidden $set hidden 1
%hidden%
$offtext
$onechoV > generated.gms
$if not set echoed $set echoed 1
%echoed%
$offecho
/* $if not set ignored $set ignored 1
%ignored% */
$IF NOT SET dimension $SET dimension 2
$if not set DIMENSION $set DIMENSION 2
$if not set run $setglobal run 1
$set console /dev/tty
set i /1*%DIMENSION%/;
$log %run% %console% %system.filesys%
$exit
$if not set dead $set dead 0
""")
        self.assertEqual(extraction.detect_options(self.source), ["dimension", "run"])

    def test_comment_markers_in_strings_preserve_references(self):
        self.source.write_text("$if not set dimension $set dimension 2\n$log '/* %dimension% */'\n")
        self.assertEqual(extraction.detect_options(self.source), ["dimension"])

    def test_unused_declarations_are_rejected_even_with_commented_references(self):
        self.source.write_text("$if not set dimension $set dimension 2\n* %dimension%\n/* %dimension% */\n")
        with self.assertRaisesRegex(ValueError, "declared but not referenced: dimension"):
            extraction.detect_options(self.source)

    def test_default_guard_must_match_assignment(self):
        self.source.write_text("$if not set dimension $set run 1\n$log %run%\n")
        with self.assertRaisesRegex(ValueError, "checks 'dimension' but sets 'run'"):
            extraction.detect_options(self.source)

    def test_missing_default_is_reported(self):
        self.source.write_text("$if not set dimension $set dimension\n$log %dimension%\n")
        with self.assertRaisesRegex(ValueError, "nonempty default"):
            extraction.detect_options(self.source)

    def test_unterminated_comments_do_not_silently_remove_options(self):
        for block in ("$ontext\n", "/* open comment\n", "$onecho > generated.gms\n"):
            with self.subTest(block=block):
                self.source.write_text(block + "$if not set dimension $set dimension 2\n")
                before = self.registry.read_bytes()
                self.assertEqual(self.cli("updateProblem")[0], 1)
                self.assertEqual(self.registry.read_bytes(), before)

    def test_registration_stores_options_and_preserves_source(self):
        self.save([])
        before = self.source.read_bytes()
        record = extraction.add_problem("MCP", self.source, self.root)
        self.assertEqual(record["options"], ["dimension"])
        self.assertEqual(extraction.load_problem_records(self.root)[0], record)
        self.assertEqual(self.source.read_bytes(), before)

    def test_failed_registration_scan_leaves_registry_and_destination_untouched(self):
        incoming = self.root / "new.gms"
        incoming.write_text("$if not set unused $set unused 2\n")
        before = self.registry.read_bytes()
        with self.assertRaises(ValueError):
            extraction.add_problem("MCP", incoming, self.root)
        self.assertEqual(self.registry.read_bytes(), before)
        self.assertFalse((self.root / "MCP" / "new.gms").exists())

    def test_update_adds_and_removes_options_preserving_other_records(self):
        other = {"name": "other", "type": "MCP", "file": "MCP/other.gms", "options": [], "note": "keep"}
        self.save([{**self.record, "note": "keep this too"}, other])
        self.source.write_text("$if not set run $set run 1\n$log %run%\n")
        before_source = self.source.read_bytes()
        code, output, error = self.cli("updateProblem")
        self.assertEqual((code, error), (0, ""))
        self.assertIn("run", output)
        data = extraction.load_problem_records(self.root)
        self.assertEqual(data[0]["options"], ["run"])
        self.assertEqual(data[0]["note"], "keep this too")
        self.assertEqual(data[1], other)
        self.assertEqual(self.source.read_bytes(), before_source)
        self.source.write_text("* No configurable inputs\n")
        self.assertEqual(self.cli("updateProblem")[0], 0)
        self.assertEqual(extraction.load_problem_records(self.root)[0]["options"], [])

    def test_update_failure_preserves_registry(self):
        before = self.registry.read_bytes()
        for content in ("$if not set unused $set unused 1\n", None):
            if content is None:
                self.source.unlink()
            else:
                self.source.write_text(content)
            code, _, error = self.cli("updateProblem")
            self.assertEqual(code, 1)
            self.assertIn("Cannot updateProblem", error)
            self.assertEqual(self.registry.read_bytes(), before)

    def test_failed_atomic_save_preserves_registry(self):
        before = self.registry.read_bytes()
        with patch.object(Path, "replace", side_effect=OSError("replace failed")):
            self.assertEqual(self.cli("updateProblem")[0], 1)
        self.assertEqual(self.registry.read_bytes(), before)
        self.assertFalse(list(self.root.glob(".problems-*")))

    def test_listing_is_read_only_and_uses_actual_source_when_metadata_is_stale(self):
        self.source.write_text("$if not set run $set run 1\n$log %run%\n")
        before = self.registry.read_bytes()
        code, output, error = self.cli("listOpt")
        self.assertEqual(code, 1)
        self.assertIn("Options for MCP/example: run", output)
        self.assertIn("gams example.gms --run=VALUE", output)
        self.assertIn("updateProblem --type MCP --select example", error)
        self.assertEqual(self.registry.read_bytes(), before)
        self.assertEqual(self.cli("updateProblem")[0], 0)
        self.assertEqual(self.cli("listOpt")[0], 0)

    def test_missing_metadata_is_reported_even_for_no_options(self):
        record = dict(self.record)
        del record["options"]
        self.save([record])
        self.source.write_text("* No options\n")
        code, output, error = self.cli("listOpt")
        self.assertEqual(code, 1)
        self.assertIn("(none)", output)
        self.assertIn("stale", error)

    def test_registry_rejects_invalid_option_metadata(self):
        for options in (None, "dimension", [1], ["--dimension"], [""], ["dimension", "DIMENSION"]):
            with self.subTest(options=options):
                self.save([{**self.record, "options": options}])
                with self.assertRaisesRegex(ValueError, "option"):
                    extraction.load_registry(self.root)

    def test_unregistered_model_cannot_be_updated_or_listed(self):
        self.save([])
        before = self.registry.read_bytes()
        for command in ("listOpt", "updateProblem"):
            code, _, error = self.cli(command)
            self.assertEqual(code, 1)
            self.assertIn("not registered", error)
        self.assertEqual(self.registry.read_bytes(), before)

    def test_commands_resolve_source_and_registry_from_script_location(self):
        import shutil
        shutil.copy2(ROOT / "extractProblem.py", self.root / "extractProblem.py")
        caller = self.root / "caller"
        caller.mkdir()
        for command in ("updateProblem", "listOpt"):
            result = subprocess.run(
                [sys.executable, str(self.root / "extractProblem.py"), command, "--type", "MCP", "--select", "example"],
                cwd=caller, env={**os.environ, "PATH": ""}, capture_output=True, text=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("dimension", result.stdout)
        self.assertEqual(list(caller.iterdir()), [])


if __name__ == "__main__":
    unittest.main()
