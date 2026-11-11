"""Checks for packaging the exact polyhedral rows with a JAMS model."""

from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

from generate_instances import embed_poly_writer, exported_poly_text

RUN_GAMS_TESTS = "--gams-tests" in sys.argv
if RUN_GAMS_TESTS:
    sys.argv.remove("--gams-tests")


SOURCE = """Variables x1, u2, u3, u4;
Equations e1, e2, e3, e4;
e1.. x1 - u2 =N= 0;
e2.. x1 =G= 1;
e3.. x1 =E= 2;
e4.. x1 =L= 3;
Model m /e1.x1, e2.u2, e3.u3, e4.u4/;
Solve m using MCP;
"""


class PolyWriterTests(unittest.TestCase):
    def test_derives_rows_from_exported_multiplier_pairings(self):
        source = SOURCE.replace("e3.u3, ", "").replace("e3.. x1 =E= 2;\n", "")
        self.assertEqual(exported_poly_text(source), "e2\ne4\n")

    def test_accepts_jams_zero_equations_for_auxiliary_primal_variables(self):
        source = SOURCE.replace("e4.u4/", "e4.u4, zero_x5.x5/")
        self.assertEqual(exported_poly_text(source), "e2\ne3\ne4\n")

    def test_preserves_model_and_places_writer_before_solve(self):
        output, count = embed_poly_writer(SOURCE, "e2\ne3\ne4\n")
        position = SOURCE.index("Solve m")
        self.assertEqual(count, 3)
        self.assertTrue(output.startswith(SOURCE[:position]))
        self.assertTrue(output.endswith(SOURCE[position:]))
        self.assertLess(output.index("putclose"), output.index("Solve m"))
        self.assertIn("= 2 to 4,", output)

    def test_gapped_rows_do_not_include_intervening_equations(self):
        output, count = embed_poly_writer(SOURCE, "e2\ne4\n")
        block = output[output.index("* Regenerate"):output.index("Solve m")]
        self.assertEqual(count, 2)
        self.assertIn("put 'e2' /;", block)
        self.assertIn("put 'e4' /;", block)
        self.assertNotIn("'e3'", block)

    def test_empty_poly_list_still_creates_file(self):
        output, count = embed_poly_writer(SOURCE, "")
        self.assertEqual(count, 0)
        self.assertIn("$onEcho > poly.txt\n$offEcho", output)

    def test_rejects_mismatched_duplicate_or_unsafe_rows(self):
        for rows in ["e5\n", "e2\ne2\n", "e2'; abort;\n"]:
            with self.subTest(rows=rows), self.assertRaises(ValueError):
                embed_poly_writer(SOURCE, rows)

    def test_ignores_commented_solves(self):
        comments = "* Solve fake using MCP;\n$onText\nSolve fake using MCP;\n$offText\n"
        output, _ = embed_poly_writer(comments + SOURCE, "e2\n")
        self.assertTrue(output.startswith(comments))
        self.assertLess(output.index("putclose"), output.rindex("Solve m"))

    def test_requires_one_mcp_solve(self):
        for source in [SOURCE.replace("Solve m using MCP;", ""), SOURCE + "Solve m using MCP;\n"]:
            with self.subTest(source=source), self.assertRaises(ValueError):
                embed_poly_writer(source, "e2\n")

    def test_does_not_redeclare_existing_symbols(self):
        source = "Scalar linlibPolyRow; File linlibPolyFile /'other.txt'/;\n" + SOURCE
        output, _ = embed_poly_writer(source, "e2\ne3\n")
        self.assertIn("File linlibPolyFile1 / 'poly.txt' /;", output)
        self.assertIn("Scalar linlibPolyRow1;", output)


@unittest.skipUnless(RUN_GAMS_TESTS, "Enable GAMS integration checks with --gams-tests")
class GamsExportTests(unittest.TestCase):
    def test_direct_export_preserves_all_constraint_types_and_bounds(self):
        here = Path(__file__).resolve().parent
        gams = shutil.which("gams")
        self.assertIsNotNone(gams)
        with tempfile.TemporaryDirectory(prefix="linlib-regression-") as directory:
            work = Path(directory)

            def run(*arguments):
                result = subprocess.run(
                    [gams, *map(str, arguments), "lo=2"], cwd=work,
                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
                )
                logs = "\n".join(p.read_text(errors="replace") for p in work.glob("*.log"))
                self.assertEqual(result.returncode, 0, result.stdout + logs[-3000:])

            declarations = (here / "generate_mcp_for_lp.gms").read_text().split("$if not set iname", 1)[0]
            declarations = declarations.replace(
                "sets i        all rows in MPS order", "sets i all rows /g,l,e,r/"
            ).replace(
                "sets j        all columns in MPS order", "sets j all columns /a,b/"
            ).replace("jc (j)   continuous columns", "jc(j) continuous columns /a,b/")
            fixture = declarations + """
ig('g')=yes; il('l')=yes; ie('e')=yes; ir('r')=yes;
c('a')=1; c('b')=2;
b('g')=1; b('l')=4; b('e')=2;
ac('g','a')=1; ac('l','b')=1;
ac('e','a')=1; ac('e','b')=1;
ac('r','a')=1; ac('r','b')=-1;
r.lo('r')=-1; r.up('r')=1;
execute_unload 'tiny.gdx', i,j,s,ig,il,ie,ir,jc,jb,ji,jsc,jsi,js1,js2,
    cobj,c,b,ac,ab,ai,asc,asi,as1,as2,xc,xb,xi,xsc,xsi,xs1,xs2,r;
"""
            (work / "fixture.gms").write_text(fixture)
            run(work / "fixture.gms")
            run(
                here / "generate_mcp_for_lp.gms", f"--iname={work / 'tiny.gdx'}",
                "--quad=0", "--batchStatus=status.txt", f"--directExport={here / 'export_lp_mcp.gms'}",
            )
            original = (work / "mcp_formulation.gms").read_text()
            poly = exported_poly_text(original)
            source, count = embed_poly_writer(original, poly)
            self.assertEqual(count, 4)
            source += """
abort$(m.solvestat <> 1 or m.modelstat > 2) 'Regression model did not solve';
abort$(abs(x1.l-1.5)>1e-6 or abs(x2.l-0.5)>1e-6) 'Incorrect LP solution';
"""
            (work / "standalone.gms").write_text(source)
            run(work / "standalone.gms", "mcp=path")
            self.assertEqual((work / "poly.txt").read_text(), poly)


if __name__ == "__main__":
    unittest.main()
