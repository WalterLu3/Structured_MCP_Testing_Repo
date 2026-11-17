"""Checks for the standalone MCP/VI extraction entry point."""

from contextlib import redirect_stderr, redirect_stdout
from io import StringIO
import json
import os
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


class ExtractionTests(ExtractionFixture):
    def test_copies_each_category_unchanged_without_running_gams(self):
        content = (
            "* Source with defaults and a polyhedral row writer\r\n"
            "$if not set dimension $set dimension 2\r\n"
            "set i /1*%dimension%/;\r\n"
            "file poly /'poly.txt'/; putclose poly 'f';\r\n"
            "solve m using mcp;\r\n"
        ).encode("utf-8")
        for category in ("MCP", "VI"):
            model = self.root / category / "example.gms"
            model.write_bytes(content)
            with self.subTest(category=category), patch.object(
                subprocess, "run", side_effect=AssertionError("Extraction must not run GAMS")
            ) as run:
                output = extraction.extract_problem(self.arguments(category), self.root)
                run.assert_not_called()
                self.assertEqual(output, self.root / "tempMCPs" / "example.gms")
                self.assertEqual(output.read_bytes(), content)
                self.assertEqual(model.read_bytes(), content)
                self.assertFalse((output.parent / "poly.txt").exists())

    def test_rejects_all_former_gams_parameter_options(self):
        for name, value in (
            ("dimension", "7"), ("nchildren", "2"), ("nstage", "3"),
            ("data", "tree2"), ("quad", "0"), ("lambda", "0.5"),
            ("alpha", "0.95"), ("demandType", "1"), ("randomSeed", "3"),
        ):
            with self.subTest(option=name), redirect_stderr(StringIO()), self.assertRaises(SystemExit) as error:
                self.arguments("MCP", f"--{name}={value}")
            self.assertEqual(error.exception.code, 2)

    def test_partial_copy_preserves_existing_outputs_and_cleans_up(self):
        output = self.root / "tempMCPs" / "example.gms"
        output.parent.mkdir()
        output.write_text("previous model")
        other = output.parent / "other.gms"
        other.write_text("another extracted model")
        stale = self.root / "example.dmp"
        stale.write_text("old dump")

        def fail(reader, writer):
            writer.write(b"partial source")
            raise OSError("copy failed")

        with patch.object(extraction.shutil, "copyfileobj", side_effect=fail):
            with self.assertRaisesRegex(OSError, "copy failed"):
                extraction.extract_problem(self.arguments(), self.root)
        self.assertEqual(output.read_text(), "previous model")
        self.assertEqual(other.read_text(), "another extracted model")
        self.assertEqual(stale.read_text(), "old dump")
        self.assertEqual(sorted(path.name for path in output.parent.iterdir()), ["example.gms", "other.gms"])

    def test_copy_preserves_a_preexisting_dump(self):
        stale = self.root / "example.dmp"
        stale.write_text("old dump")
        output = extraction.extract_problem(self.arguments(), self.root)
        self.assertEqual(output.read_bytes(), (self.root / "MCP" / "example.gms").read_bytes())
        self.assertEqual(stale.read_text(), "old dump")

    def test_copy_ignores_a_directory_with_the_dump_filename(self):
        directory = self.root / "example.dmp"
        directory.mkdir()
        (directory / "keep.txt").write_text("keep this directory")
        extraction.extract_problem(self.arguments(), self.root)
        self.assertEqual((directory / "keep.txt").read_text(), "keep this directory")

    def test_failed_replacement_preserves_existing_output_and_cleans_up(self):
        output = self.root / "tempMCPs" / "example.gms"
        output.parent.mkdir()
        output.write_text("previous model")
        with patch.object(Path, "replace", side_effect=OSError("replace failed")):
            with self.assertRaisesRegex(OSError, "replace failed"):
                extraction.extract_problem(self.arguments(), self.root)
        self.assertEqual(output.read_text(), "previous model")
        self.assertEqual(list(output.parent.iterdir()), [output])

    def test_different_model_names_keep_separate_outputs(self):
        (self.root / "VI" / "other.gms").write_text("second model")

        first = extraction.extract_problem(self.arguments(), self.root)
        args = self.arguments("VI")
        args.select = "other"
        second = extraction.extract_problem(args, self.root)
        self.assertEqual(first, self.root / "tempMCPs" / "example.gms")
        self.assertEqual(second, self.root / "tempMCPs" / "other.gms")
        self.assertEqual(first.read_text(), "* A standalone model\n")
        self.assertEqual(second.read_text(), "second model")

    def test_same_name_from_another_type_replaces_only_that_output(self):
        first = extraction.extract_problem(self.arguments("MCP"), self.root)
        first.write_text("old extracted model")
        second = extraction.extract_problem(self.arguments("VI"), self.root)
        self.assertEqual(first, second)
        self.assertEqual(second.read_bytes(), (self.root / "VI" / "example.gms").read_bytes())

    def test_legacy_root_output_is_preserved(self):
        legacy = self.root / "tempMCP.gms"
        legacy.write_text("old root output")
        result = extraction.extract_problem(self.arguments(), self.root)
        self.assertEqual(result, self.root / "tempMCPs" / "example.gms")
        self.assertEqual(legacy.read_text(), "old root output")

    def test_output_folder_conflict_preserves_the_existing_file(self):
        conflict = self.root / "tempMCPs"
        conflict.write_text("existing user file")
        with self.assertRaises(OSError):
            extraction.extract_problem(self.arguments(), self.root)
        self.assertEqual(conflict.read_text(), "existing user file")
        self.assertFalse((self.root / "example.dmp").exists())

    def test_output_folder_symlink_cannot_redirect_writes_into_sources(self):
        output_dir = self.root / "tempMCPs"
        try:
            output_dir.symlink_to(self.root / "MCP", target_is_directory=True)
        except OSError:
            self.skipTest("Symbolic links are not available")
        model = self.root / "MCP" / "example.gms"
        before = model.read_bytes()
        with self.assertRaisesRegex(RuntimeError, "symlink"):
            extraction.extract_problem(self.arguments(), self.root)
        self.assertEqual(model.read_bytes(), before)
        self.assertTrue(output_dir.is_symlink())

    def test_output_cannot_replace_a_source_stored_in_temp_mcps(self):
        model = self.root / "tempMCPs" / "example.gms"
        model.parent.mkdir()
        model.write_text("source model")
        with self.assertRaisesRegex(RuntimeError, "overwrite the source model"):
            extraction.extract_problem(self.arguments("tempMCPs"), self.root)
        self.assertEqual(model.read_text(), "source model")

    def test_missing_model_does_not_fall_back_to_gdx_conversion(self):
        (self.root / "VI" / "example.gms").unlink()
        dataset = self.root / "VI" / "LINLib" / "instances" / "example.gdx"
        dataset.parent.mkdir(parents=True)
        dataset.write_text("a dataset is not a standalone model")
        with patch.object(subprocess, "run") as run:
            with self.assertRaisesRegex(FileNotFoundError, "list --type VI"):
                extraction.extract_problem(self.arguments("VI"), self.root)
        run.assert_not_called()

    def test_rejects_model_names_outside_the_selected_folder(self):
        for name in ("../example", "..", "sub/example", "sub\\example", ""):
            args = self.arguments()
            args.select = name
            with self.subTest(name=name), patch.object(subprocess, "run") as run:
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
            subprocess, "run"
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
            subprocess, "run"
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
        with patch.object(extraction, "BASE_DIR", self.root), redirect_stdout(StringIO()):
            code = extraction.main(["extract", "--type", "MCP", "--select", "example"])
        self.assertEqual(code, 0)
        self.assertTrue((self.root / "tempMCPs" / "example.gms").is_file())

    def test_cli_reports_copy_failure_without_a_python_traceback(self):
        error = StringIO()
        with patch.object(extraction, "BASE_DIR", self.root), patch.object(
            extraction.shutil, "copyfileobj", side_effect=OSError("copy failed")
        ), redirect_stdout(StringIO()), redirect_stderr(error):
            code = extraction.main(["extract", "--type", "MCP", "--select", "example"])
        self.assertEqual(code, 1)
        self.assertIn("Extraction failed: copy failed", error.getvalue())
        self.assertFalse((self.root / "tempMCPs" / "example.gms").exists())

    def test_extraction_succeeds_without_gams_installed(self):
        error = StringIO()
        with patch.object(extraction, "BASE_DIR", self.root), patch.object(
            subprocess, "run", side_effect=FileNotFoundError("gams")
        ) as run, redirect_stdout(StringIO()), redirect_stderr(error):
            code = extraction.main(["extract", "--type", "MCP", "--select", "example"])
        self.assertEqual(code, 0)
        self.assertEqual(error.getvalue(), "")
        run.assert_not_called()


class TypeRegistrationTests(ExtractionFixture):
    def test_add_type_creates_folder_and_preserves_existing_records(self):
        before = extraction.load_problem_records(self.root)
        output = StringIO()
        with patch.object(extraction, "BASE_DIR", self.root), patch.object(
            subprocess, "run"
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
        output_path = extraction.extract_problem(self.arguments("NCP"), self.root)
        self.assertEqual(output_path.read_text(), "* A custom problem\n")

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
        for command in ("addType", "addProblem", "list", "extract"):
            options = [command, "--type", "../outside"]
            if command == "extract":
                options.extend(["--select", "example"])
            elif command == "addProblem":
                options.extend(["--file", "unused.gms"])
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


class ProblemRegistrationTests(ExtractionFixture):
    def source_file(self, filename="newProblem.gms"):
        incoming = self.root / "incoming files"
        incoming.mkdir(exist_ok=True)
        source = incoming / filename
        source.write_bytes(b"* GAMS model\r\nVariable x; Equation f;\r\nf.. x =N= 0;\r\nModel m /f.x/;\r\nSolve m using mcp;\r\n")
        return source

    def test_add_problem_copies_bytes_and_registers_without_running_gams(self):
        source = self.source_file()
        previous = extraction.load_problem_records(self.root)
        output = StringIO()
        with patch.object(extraction, "BASE_DIR", self.root), patch.object(
            subprocess, "run"
        ) as run, redirect_stdout(output):
            code = extraction.main(["addProblem", "--type", "MCP", "--file", str(source)])
        self.assertEqual(code, 0)
        self.assertIn("Registered problem 'MCP/newProblem'", output.getvalue())
        self.assertEqual((self.root / "MCP" / "newProblem.gms").read_bytes(), source.read_bytes())
        self.assertEqual(extraction.load_problem_records(self.root), previous + [
            {"name": "newProblem", "type": "MCP", "file": "MCP/newProblem.gms", "options": []}
        ])
        run.assert_not_called()

    def test_registers_a_file_already_in_its_type_folder(self):
        source = self.root / "VI" / "newProblem.gms"
        source.write_bytes(b"existing user model")
        with patch.object(extraction.shutil, "copyfileobj") as copy:
            record = extraction.add_problem("VI", source, self.root)
        self.assertEqual(record, {"name": "newProblem", "type": "VI", "file": "VI/newProblem.gms", "options": []})
        self.assertEqual(source.read_bytes(), b"existing user model")
        copy.assert_not_called()

    def test_new_problem_immediately_appears_in_list(self):
        extraction.add_problem("VI", self.source_file(), self.root)
        output = StringIO()
        with patch.object(extraction, "BASE_DIR", self.root), redirect_stdout(output):
            code = extraction.main(["list", "--type", "VI"])
        self.assertEqual(code, 0)
        self.assertEqual(output.getvalue().splitlines(), ["example", "newProblem"])

    def test_imported_problem_can_be_extracted_from_a_custom_type(self):
        extraction.add_type("NCP", self.root)
        extraction.add_problem("NCP", self.source_file(), self.root)
        args = extraction.parse_arguments(["extract", "--type", "NCP", "--select", "newProblem"])
        result = extraction.extract_problem(args, self.root)
        self.assertEqual(result.read_bytes(), (self.root / "NCP" / "newProblem.gms").read_bytes())

    def test_duplicate_registration_and_case_variant_preserve_data(self):
        source = self.source_file()
        extraction.add_problem("MCP", source, self.root)
        previous = (self.root / "problems.json").read_bytes()
        content = (self.root / "MCP" / "newProblem.gms").read_bytes()
        for candidate in (source, self.source_file("NEWPROBLEM.gms")):
            with self.subTest(candidate=candidate), self.assertRaisesRegex(ValueError, "already registered"):
                extraction.add_problem("MCP", candidate, self.root)
        self.assertEqual((self.root / "problems.json").read_bytes(), previous)
        self.assertEqual((self.root / "MCP" / "newProblem.gms").read_bytes(), content)

    def test_existing_unregistered_destination_is_not_overwritten(self):
        source = self.source_file()
        destination = self.root / "MCP" / source.name
        destination.write_bytes(b"original user file")
        previous = (self.root / "problems.json").read_bytes()
        with self.assertRaisesRegex(ValueError, "Destination already exists"):
            extraction.add_problem("MCP", source, self.root)
        self.assertEqual(destination.read_bytes(), b"original user file")
        self.assertEqual((self.root / "problems.json").read_bytes(), previous)

    def test_unknown_type_does_not_create_a_folder_or_change_registry(self):
        source = self.source_file()
        previous = (self.root / "problems.json").read_bytes()
        with self.assertRaisesRegex(ValueError, "Use addType"):
            extraction.add_problem("NCP", source, self.root)
        self.assertFalse((self.root / "NCP").exists())
        self.assertEqual((self.root / "problems.json").read_bytes(), previous)

    def test_missing_file_wrong_extension_and_directories_are_rejected(self):
        missing = self.root / "missing.gms"
        wrong_extension = self.source_file("newProblem.txt")
        directory = self.root / "directory.gms"
        directory.mkdir()
        previous = (self.root / "problems.json").read_bytes()
        for source in (missing, wrong_extension, directory):
            with self.subTest(source=source), self.assertRaises((OSError, ValueError)):
                extraction.add_problem("MCP", source, self.root)
        self.assertEqual((self.root / "problems.json").read_bytes(), previous)

    def test_unresolvable_source_path_reports_a_readable_cli_error(self):
        error = StringIO()
        with patch.object(extraction, "BASE_DIR", self.root), patch.object(
            Path, "expanduser", side_effect=RuntimeError("Cannot resolve source home directory")
        ), redirect_stderr(error):
            code = extraction.main(["addProblem", "--type", "MCP", "--file", "~/newProblem.gms"])
        self.assertEqual(code, 1)
        self.assertIn("Cannot add problem: Cannot resolve source home directory", error.getvalue())

    def test_uppercase_source_extension_has_a_canonical_destination(self):
        source = self.source_file("newProblem.GMS")
        record = extraction.add_problem("MCP", source, self.root)
        self.assertEqual(record["file"], "MCP/newProblem.gms")
        self.assertEqual((self.root / record["file"]).read_bytes(), source.read_bytes())

    def test_same_name_can_be_added_to_different_types(self):
        source = self.source_file()
        first = extraction.add_problem("MCP", source, self.root)
        second = extraction.add_problem("VI", source, self.root)
        self.assertEqual(first["name"], second["name"])
        self.assertNotEqual(first["file"], second["file"])
        self.assertEqual((self.root / first["file"]).read_bytes(), (self.root / second["file"]).read_bytes())

    def test_failed_registry_save_removes_only_the_new_copy(self):
        source = self.source_file()
        previous = (self.root / "problems.json").read_bytes()
        content = source.read_bytes()
        with patch.object(extraction, "save_registry", side_effect=OSError("write failed")), self.assertRaises(OSError):
            extraction.add_problem("MCP", source, self.root)
        self.assertFalse((self.root / "MCP" / source.name).exists())
        self.assertEqual(source.read_bytes(), content)
        self.assertEqual((self.root / "problems.json").read_bytes(), previous)
        self.assertTrue((self.root / "MCP" / "example.gms").is_file())

    def test_failed_registry_save_preserves_an_in_place_source(self):
        source = self.root / "MCP" / "newProblem.gms"
        source.write_bytes(b"existing user model")
        previous = (self.root / "problems.json").read_bytes()
        with patch.object(extraction, "save_registry", side_effect=OSError("write failed")), self.assertRaises(OSError):
            extraction.add_problem("MCP", source, self.root)
        self.assertEqual(source.read_bytes(), b"existing user model")
        self.assertEqual((self.root / "problems.json").read_bytes(), previous)

    def test_partial_copy_is_removed_when_reading_fails(self):
        source = self.source_file()
        previous = (self.root / "problems.json").read_bytes()

        def fail(reader, writer):
            writer.write(b"partial")
            raise OSError("copy failed")

        with patch.object(extraction.shutil, "copyfileobj", side_effect=fail), self.assertRaises(OSError):
            extraction.add_problem("MCP", source, self.root)
        self.assertFalse((self.root / "MCP" / source.name).exists())
        self.assertTrue(source.is_file())
        self.assertEqual((self.root / "problems.json").read_bytes(), previous)

    def test_missing_registered_folder_is_created_and_rolled_back_on_failure(self):
        source = self.source_file()
        data = extraction.load_registry(self.root)
        data["types"].append("NCP")
        extraction.save_registry(self.root, data)
        previous = (self.root / "problems.json").read_bytes()
        with patch.object(extraction, "save_registry", side_effect=OSError("write failed")), self.assertRaises(OSError):
            extraction.add_problem("NCP", source, self.root)
        self.assertFalse((self.root / "NCP").exists())
        self.assertEqual((self.root / "problems.json").read_bytes(), previous)
        extraction.add_problem("NCP", source, self.root)
        self.assertTrue((self.root / "NCP" / source.name).is_file())

    def test_destination_symlink_is_not_followed(self):
        source = self.source_file()
        target = self.root / "MCP" / source.name
        try:
            target.symlink_to(source)
        except OSError:
            self.skipTest("Symbolic links are not available")
        previous = (self.root / "problems.json").read_bytes()
        content = source.read_bytes()
        with self.assertRaisesRegex(ValueError, "Destination already exists"):
            extraction.add_problem("MCP", source, self.root)
        self.assertTrue(target.is_symlink())
        self.assertEqual(source.read_bytes(), content)
        self.assertEqual((self.root / "problems.json").read_bytes(), previous)


class BatchExtractionTests(ExtractionFixture):
    def batch(self, content):
        source = self.root / "problems.txt"
        source.write_text(content, encoding="utf-8")
        output, error = StringIO(), StringIO()
        with patch.object(extraction, "BASE_DIR", self.root), redirect_stdout(output), redirect_stderr(error):
            code = extraction.main(["extractList", "--file", str(source)])
        return code, output.getvalue(), error.getvalue()

    def test_names_resolve_across_types_and_outputs_coexist(self):
        records = [
            {"name": "example", "type": "MCP", "file": "MCP/example.gms"},
            {"name": "other", "type": "VI", "file": "VI/other.gms"},
        ]
        self.write_records(records)
        (self.root / "VI" / "other.gms").write_text("* Another model\n")
        with patch.object(subprocess, "run") as run:
            code, output, error = self.batch("\ufeff# problems.txt\n\n example \nother # a VI\nexample\n")
        self.assertEqual(code, 0)
        run.assert_not_called()
        for record in records:
            self.assertEqual(
                (self.root / "tempMCPs" / f"{record['name']}.gms").read_bytes(),
                (self.root / record["file"]).read_bytes(),
            )
        self.assertIn("2 extracted, 1 skipped, 0 failed", output)
        self.assertIn("problems.txt:5: example: duplicate", error)

    def test_legacy_parameter_metadata_does_not_skip_copying(self):
        self.write_records([{
            "name": "example", "type": "MCP", "file": "MCP/example.gms",
            "required_arguments": ["dimension", "randomSeed"],
        }])
        previous = self.root / "tempMCPs" / "example.gms"
        previous.parent.mkdir()
        previous.write_text("previous extraction")
        source = self.root / "MCP" / "example.gms"
        source.write_text("$if not set dimension $set dimension 2\nset i /1*%dimension%/;\n")
        with patch.object(subprocess, "run") as run:
            code, output, error = self.batch("example\n")
        run.assert_not_called()
        self.assertEqual(code, 0)
        self.assertEqual(previous.read_bytes(), source.read_bytes())
        self.assertIn("1 extracted, 0 skipped, 0 failed", output)
        self.assertEqual(error, "")

    def test_unknown_and_ambiguous_names_are_not_copied(self):
        with patch.object(subprocess, "run") as run:
            code, output, error = self.batch("missing\nexample\n")
        run.assert_not_called()
        self.assertEqual(code, 1)
        self.assertIn("missing: not registered", error)
        self.assertIn("example: registered under multiple types: MCP, VI", error)
        self.assertIn("0 extracted, 0 skipped, 2 failed", output)
        self.assertFalse((self.root / "tempMCPs").exists())

    def test_missing_model_does_not_stop_later_extractions(self):
        self.write_records([
            {"name": "missing", "type": "VI", "file": "VI/missing.gms"},
            {"name": "example", "type": "MCP", "file": "MCP/example.gms"},
        ])
        code, output, error = self.batch("missing\nexample\n")
        self.assertEqual(code, 1)
        self.assertIn("Model not found", error)
        self.assertIn("1 extracted, 0 skipped, 1 failed", output)
        self.assertTrue((self.root / "tempMCPs" / "example.gms").is_file())

    def test_copy_failure_preserves_old_output_and_continues(self):
        self.write_records([
            {"name": "broken", "type": "VI", "file": "VI/broken.gms"},
            {"name": "example", "type": "MCP", "file": "MCP/example.gms"},
        ])
        (self.root / "VI" / "broken.gms").write_text("invalid source")
        previous = self.root / "tempMCPs" / "broken.gms"
        previous.parent.mkdir()
        previous.write_text("previous extraction")

        copy_source = shutil.copyfileobj

        def copy_model(reader, writer):
            if Path(reader.name).stem == "broken":
                writer.write(b"partial source")
                raise OSError("copy failed")
            copy_source(reader, writer)

        with patch.object(extraction.shutil, "copyfileobj", side_effect=copy_model):
            code, output, error = self.batch("broken\nexample\n")
        self.assertEqual(code, 1)
        self.assertEqual(previous.read_text(), "previous extraction")
        self.assertTrue((self.root / "tempMCPs" / "example.gms").is_file())
        self.assertIn("copy failed", error)
        self.assertIn("1 extracted, 0 skipped, 1 failed", output)

    def test_empty_list_does_not_create_output_folder(self):
        with patch.object(subprocess, "run") as run:
            code, output, error = self.batch("# Nothing selected\n\n")
        run.assert_not_called()
        self.assertEqual(code, 0)
        self.assertIn("0 extracted, 0 skipped, 0 failed", output)
        self.assertFalse((self.root / "tempMCPs").exists())
        self.assertEqual(error, "")

    def test_missing_or_invalid_utf8_list_has_a_friendly_error(self):
        source = self.root / "missing.txt"
        for content in (None, b"\xff\xff"):
            if content is not None:
                source.write_bytes(content)
            error = StringIO()
            with patch.object(extraction, "BASE_DIR", self.root), patch.object(
                subprocess, "run"
            ) as run, redirect_stderr(error):
                code = extraction.main(["extractList", "--file", str(source)])
            run.assert_not_called()
            self.assertEqual(code, 1)
            self.assertIn("Cannot extract problem list", error.getvalue())


class CliExtractionFixture(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="extract-cli-")
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name).resolve() / "repo with spaces"
        self.caller = Path(self.directory.name).resolve() / "caller"
        self.root.mkdir()
        self.caller.mkdir()
        (self.root / "MCP").mkdir()
        (self.root / "VI").mkdir()
        shutil.copy2(ROOT / "extractProblem.py", self.root / "extractProblem.py")
        # The extractor must work even when GAMS cannot be found on PATH.
        self.environment = {**os.environ, "PATH": ""}

    def extract(self, category, name):
        result = subprocess.run(
            [sys.executable, str(self.root / "extractProblem.py"), "extract", "--type", category, "--select", name],
            cwd=self.caller, env=self.environment, text=True,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        )
        self.assertEqual(result.returncode, 0, result.stdout[-3000:])
        self.assertFalse((self.caller / "tempMCPs").exists())
        output = self.root / "tempMCPs" / f"{name}.gms"
        self.assertIn(str(output), result.stdout)
        self.assertFalse((self.root / "tempMCP.gms").exists())
        self.assertEqual(output.read_bytes(), (self.root / category / f"{name}.gms").read_bytes())
        return output

    def run_gams(self, model, *options):
        result = subprocess.run(
            ["gams", str(model), "lo=2", *options], cwd=model.parent,
            text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        )
        log = model.with_suffix(".log")
        self.assertEqual(result.returncode, 0, result.stdout + (log.read_text()[-3000:] if log.exists() else ""))


class CliExtractionTests(CliExtractionFixture):
    def test_copies_source_without_preprocessing_or_execution(self):
        model = self.root / "MCP" / "toy.gms"
        model.write_text("""$if not set dimension $set dimension 2
set i /1*%dimension%/;
file sentinel /'executed.txt'/;
putclose sentinel 'The model was executed';
""")
        output = self.extract("MCP", "toy")
        self.assertFalse((output.parent / "executed.txt").exists())
        self.assertFalse((self.root / "executed.txt").exists())
        self.assertFalse(list(self.root.rglob("*.lst")))
        # GAMS syntax validation is deferred until the user runs the model.
        model.write_text("not a valid GAMS model;\n")
        self.extract("MCP", "toy")

    def test_batch_preserves_defaults_from_another_working_directory(self):
        records = [
            {"name": "defaulted", "type": "MCP", "file": "MCP/defaulted.gms"},
            {"name": "other", "type": "VI", "file": "VI/other.gms"},
        ]
        (self.root / "MCP" / "defaulted.gms").write_text(
            "$if not set dimension $set dimension 2\nset i /1*%dimension%/;\n"
        )
        (self.root / "VI" / "other.gms").write_text("* Another standalone model\n")
        (self.root / "problems.json").write_text(json.dumps({"problems": records}))
        (self.caller / "problems.txt").write_text("# Models\nother\ndefaulted\n")
        result = subprocess.run(
            [sys.executable, str(self.root / "extractProblem.py"), "extractList", "--file", "problems.txt"],
            cwd=self.caller, env=self.environment, text=True,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        )
        self.assertEqual(result.returncode, 0, result.stdout[-2000:] + result.stderr)
        self.assertIn("2 extracted, 0 skipped, 0 failed", result.stdout)
        self.assertEqual(result.stderr, "")
        for record in records:
            self.assertEqual(
                (self.root / "tempMCPs" / f"{record['name']}.gms").read_bytes(),
                (self.root / record["file"]).read_bytes(),
            )
        self.assertFalse(list(self.root.rglob("*.lst")))
        self.assertFalse((self.caller / "tempMCPs").exists())


@unittest.skipUnless(RUN_GAMS_TESTS, "Enable GAMS integration checks with --gams-tests")
class GamsRunTests(CliExtractionFixture):
    def test_copied_model_uses_defaults_and_gams_command_line_overrides(self):
        model = self.root / "MCP" / "toy.gms"
        model.write_text("""$if not set dimension $set dimension 2
set i /1*%dimension%/;
positive variable x(i);
equation f(i);
f(i).. x(i) - 1 =g= 0;
model m /f.x/;
file actual /'dimension.txt'/;
putclose actual card(i):0:0;
solve m using mcp;
abort$(m.solvestat <> 1) 'Solver did not finish normally';
""")
        output = self.extract("MCP", "toy")
        before = output.read_bytes()
        for options, expected in (([], "2"), (["--dimension=4"], "4")):
            with self.subTest(options=options):
                self.run_gams(output, "mcp=path", *options)
                self.assertEqual((output.parent / "dimension.txt").read_text().strip(), expected)
                self.assertEqual(output.read_bytes(), before)

    def test_repository_models_compile_with_defaults_and_dimension_overrides(self):
        for name, set_name, first, default in (
            ("bai_haung", "t", 1, 200), ("bratu", "I", 0, 76), ("dirkse2", "I", 1, 25),
        ):
            shutil.copy2(ROOT / "MCP" / f"{name}.gms", self.root / "MCP" / f"{name}.gms")
            output = self.extract("MCP", name)
            for options, expected in (([], default), (["--dimension=3"], 3)):
                with self.subTest(model=name, options=options):
                    self.run_gams(output, "action=c", "dumpOpt=21", *options)
                    expanded = output.with_suffix(".dmp").read_text()
                    self.assertRegex(expanded, rf"(?i)\b{set_name}\s*/\s*{first}\s*\*\s*{expected}\s*/")
                    self.assertEqual(output.read_bytes(), (self.root / "MCP" / output.name).read_bytes())

    def test_extracted_lp_retains_its_standalone_poly_writer(self):
        shutil.copy2(ROOT / "VI" / "agg.gms", self.root / "VI" / "agg.gms")
        output = self.extract("VI", "agg")
        check, solves = re.subn(r"(?im)^([ \t]*solve[^\n]+;)[ \t]*$", r"* \1", output.read_text())
        self.assertEqual(solves, 1)
        check_path = output.parent / "check_poly.gms"
        check_path.write_text(check)
        self.run_gams(check_path)
        self.assertEqual((output.parent / "poly.txt").read_text().splitlines(), [f"e{i}" for i in range(164, 652)])
        self.assertFalse((self.root / "poly.txt").exists())


if __name__ == "__main__":
    unittest.main()
