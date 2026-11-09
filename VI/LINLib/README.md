# LINLib Model Library

This is a large collection of linear and quadratic models. Some of the the instances also contain discrete variables. Models are from https://github.com/GAMS-dev/gamsworld/tree/master/LINLib (details of each model can also found in this link)

## Generate standalone MCP models

From the repository root, export the continuous LP instances to `VI/<instance>.gms`:

```bash
python3 VI/LINLib/generate_instances.py --verify
```

For example, `instances/agg.gdx` produces `VI/agg.gms`. Each exported file contains the MCP formulation and GAMS code that recreates its matching `poly.txt` before the final solve. The exported model can be run without the original GDX file or the Python extraction helper:

```bash
cd VI
gams agg.gms mcp=path
```

`poly.txt` is written in the run's working directory. For a PATHVI run, enable a solver option file containing `crash_method pathvi` and `pathvi_filename poly.txt`, using a PATH build that supports those options.

To generate only selected instances, or rebuild existing exports:

```bash
python3 VI/LINLib/generate_instances.py --select agg agg2 --verify
python3 VI/LINLib/generate_instances.py --overwrite --verify
```

The generator uses `instances/` as its input directory and `VI/` as its output directory by default. Existing output files are skipped unless `--overwrite` is supplied. Other directories can be selected with `--instances-dir` and `--output-dir`.

Only continuous LPs are exported, with `--quad=0`. Instances with discrete variables, quadratic terms, or cones are skipped. The summary and per-instance results are recorded in `generation_report.json`; failed conversions have diagnostic logs in `generation_logs/`.

Most exports preserve the JAMS-generated MCP source and insert the polyhedral row writer. The row names come from the exported complementarity pairs because JAMS can remove rows during preprocessing. Consecutive row names are written with compact GAMS loops, and models with no polyhedral rows create an empty file. If JAMS rejects a continuous LP before writing a model, `export_lp_mcp.gms` exports its affine VI's KKT system directly, retaining fixed bounds, constant constraints, and ranged rows. The report identifies these fallback exports.

With `--verify`, the generator executes a temporary copy of each new model with its final solve disabled and checks that it recreates the expected row list. This checks the standalone source and polyhedral metadata without solving the benchmark instances.

Packaging tests can be run with `python3 -B -m unittest discover -s VI/LINLib -p 'test_generate_instances.py'`. The optional GAMS regression test, `python3 -B VI/LINLib/test_generate_instances.py --gams-tests`, also checks the direct exporter on a small LP with equality, inequality, and ranged constraints.


## What does the experiment do?

We reformulate an LP problem as an AVI problem, and solve it using PATH and PATHVI as crash method.

You can run the experiment in the following way.

`bash virun_buff.sh <instance_name>`

where instance_name is the name of the GDX file in `instances/` folder (e.g. `10teams.gdx`).

** Note that the script will only run on the problems which are LP problems and only contain continuous variables, as there are some MIP problems and quadratic problems in LINLIB.

The result will be stored in a created folder `logs/` and the running log of PATH and PATHVI as crash method will be concatenated and stored in `logs/<instance_name>.log`.

## Change of PATH options and PATHVI options

The normal PATH option is specified in path.opt and the PATHVI as crash is specified in pathvicrash.opt.

