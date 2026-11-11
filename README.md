# Structured MCP Testing Repository

This repository contains models, scripts, and computational experiments for studying structured equilibrium problems. It supports two main workflows:

- Generate mixed complementarity problem (MCP) instances, including MCPs with variational inequality (VI) structure, and add new test problems.
- Reproduce the thesis experiments on PATHVI, linear algebra basis packages, stochastic optimization, and stochastic equilibrium.

General MCP/VI extraction uses `extractProblem.py` from the repository root. Stochastic optimization and stochastic equilibrium experiments are run directly from their respective directories.

## Requirements

- **Python 3** for the extraction scripts. These scripts use only the Python standard library.
- **GAMS**, with the `gams` executable available on your `PATH` and a valid license for the selected model size and solvers.
- **PATH** for solving MCPs.
- **EMP support**, including JAMS or ReSHOP as required by the selected model. The stochastic equilibrium algorithms and several stochastic optimization experiments use ReSHOP, including its embedded modeling syntax. Other experiments use PATHNLP or an LP/NLP solver.
- **An experimental PATH build** for the PATHVI crash method and the experimental basis package options. Availability depends on the solver build; these options should not be assumed to exist in a standard installation.
- **A compiled UMFPACK basis library** when testing the UMFPACK option.

The optional Jacobian visualization tool also requires `gams.transfer` and Matplotlib. See [visualization_tool/README.md](visualization_tool/README.md).

The `solver` entry in the current checkout is an empty placeholder file. Experimental solver binaries and installation instructions are not bundled there; configure the required solver build in GAMS before running the corresponding experiments.

## Repository layout

| Path | Purpose |
| --- | --- |
| [`extractProblem.py`](extractProblem.py) | Register, list, or extract models individually or from a text list. |
| [`problems.json`](problems.json) | Central registry of types, problem names, source files, and required arguments. |
| [`problems.txt`](problems.txt) | Example names-only list for batch extraction. |
| [`MCP/`](MCP/) | Standard MCP models, including selected MCPLIB problems. |
| [`VI/`](VI/) | Standalone models with VI structure and supporting experiments. |
| [`VI/LINLib/`](VI/LINLib/) | LINLib instances and scripts for reformulating continuous LPs as VIs/MCPs. |
| [`VI/vimod/`](VI/vimod/) | Additional VI datasets and experiment scripts. |
| [`VI/small_test/`](VI/small_test/) | Small VI examples and solver option files. |
| [`stochastic_optimization/`](stochastic_optimization/) | Clear Lake stochastic optimization models and solution algorithms. |
| [`stochastic_equilibrium/`](stochastic_equilibrium/) | Stochastic equilibrium models, scenario-tree data, and risk decomposition algorithms. |
| [`reshop_demo/`](reshop_demo/) | Additional ReSHOP demonstrations. |
| [`visualization_tool/`](visualization_tool/) | Tools for inspecting Jacobian structure. |

## Getting started

Clone the repository and change to its root directory:

```bash
git clone https://github.com/WalterLu3/Structured_MCP_Testing_Repo.git
cd Structured_MCP_Testing_Repo
```

The examples below use `python3`; `python` can be used if it points to Python 3.

List the standalone model names available for extraction:

```bash
python3 extractProblem.py list --type MCP
python3 extractProblem.py list --type VI
```

Generate a small MCP instance and solve it with PATH:

```bash
python3 extractProblem.py extract \
    --type MCP \
    --select bai_haung \
    --dimension 10

cd tempMCPs
gams bai_haung.gms mcp=path
cd ..
```

The generated model is saved as `tempMCPs/bai_haung.gms`. The `tempMCPs/` folder is created automatically and ignored by Git. Extracted models with different names can coexist; extracting the same name again replaces that file after a successful compilation. Names are shared across types, so models with the same `--select` value use the same output path. An existing root-level `tempMCP.gms` is left untouched.

To extract several registered models, put one name per line in a text file, such as the included [`problems.txt`](problems.txt):

```text
# problems.txt
agg
bai_haung
dirkse2
```

```bash
python3 extractProblem.py extractList --file problems.txt
```

The command looks up each name across all types in `problems.json`; no `--type` is needed. This example generates `tempMCPs/agg.gms`, `tempMCPs/bai_haung.gms`, and `tempMCPs/dirkse2.gms`. Model defaults are used without overrides, including the default dimensions of `bai_haung` and `dirkse2`. Extraction compiles the models without executing their solve statements.

Blank lines and comments starting with `#` are ignored. Repeated names are extracted once. A model whose registry record lists `required_arguments` is skipped with a warning asking the user to generate it separately with the necessary arguments. These skips leave existing outputs untouched. Required arguments are declared in the registry by the model author, rather than inferred from GAMS source; see the registration instructions below.

Unknown names, names registered under multiple types, missing source files, and compilation errors are reported, and the command continues with later names. Resolve ambiguous names with the single-model `extract --type ... --select ...` command. A final summary reports extracted, skipped, and failed entries. The exit status is nonzero if any entries failed; skipping declared required arguments or duplicates alone is successful. The input file path is relative to the caller's working directory; outputs always go into this repository's `tempMCPs/` folder.

## Extracting problem instances

The examples below assume the repository root as the current directory:

```text
python3 extractProblem.py extract --type PROBLEM_TYPE --select MODEL_NAME [OPTIONS]
```

| Argument | Description |
| --- | --- |
| `--type` | Required. Selects the type folder, initially `MCP` or `VI`. |
| `--select` | Required. Selects the model name without the `.gms` extension. |
| `--dimension` | Sets the dimension for models that use this parameter. Supply it when extracting a parameterized model; other models have fixed sizes. |

The root script selects `<type>/<model>.gms` and calls GAMS directly. Model lookup and compilation use the script's directory, and output is written to `<repository>/tempMCPs/<model>.gms`, regardless of the directory from which the script is invoked. The script prints the completed output path.

Only explicitly supplied modeling parameters are forwarded to GAMS, using names such as `--dimension=200`. Omitted parameters retain the defaults defined by the model. Extraction replaces the selected output file only after a successful compilation; a failed compilation preserves existing outputs.

For example, generate the thesis MCP example with dimension 200:

```bash
python3 extractProblem.py extract \
    --type MCP \
    --select bai_haung \
    --dimension 200
```

To extract an existing VI-structured MCP, use the Bertsekas optimal control model:

```bash
python3 extractProblem.py extract \
    --type VI \
    --select bert_oc
```

This VI model has a fixed mesh in its source file, so the example does not pass `--dimension`.

Extraction uses GAMS compilation (`action=c`, `dumpOpt=21`) to expand the selected source without executing its solve statements. Models already expressed as MCPs can then be solved from `tempMCPs/<model>.gms`. Embedded GAMS code that writes `poly.txt` is retained in the extracted source. A source model that uses EMP still requires the corresponding EMP solver when executed.

GAMS writes relative output files, including `poly.txt`, in the run's working directory. Run models from `tempMCPs/` to keep these files beside the extracted source. Solver option files and any other runtime inputs must also be available in that working directory. Running `gams tempMCPs/<model>.gms` from the repository root instead uses the repository root as the working directory.

The `list` command reads the central [`problems.json`](problems.json) registry and prints registered model names for the requested type in alphabetical order. Only models whose source files exist locally are printed; missing registered files produce warnings on standard error. Unregistered files and helper scripts are not listed. For example, the dataset loader `VI/vimod.gms` is not registered as a standalone problem.

The registry includes the large generated models excluded from Git. Their registrations remain valid when the corresponding files are missing from a checkout; generate the files locally to make them available for listing and extraction. Consult the collection-specific documentation for model inputs. The thesis's `exampleVI` is an example users can add rather than an existing registered problem.

Help is available with:

```bash
python3 extractProblem.py --help
python3 extractProblem.py extract --help
```

The existing parameter flags shown by `extract --help` remain available and are forwarded directly to GAMS when supplied. They affect models that reference the corresponding GAMS parameters; the numerical data in pre-generated LP models are fixed at generation time. Type folders start with `MCP` and `VI` and can be extended with `addType`. Use the GAMS entry points below for stochastic experiments.

### Generating the LINLib LP collection

Export the continuous LPs in `VI/LINLib/instances/` as standalone `VI/<instance>.gms` models:

```bash
python3 VI/LINLib/generate_instances.py --verify
```

Each generated file includes GAMS code that writes its own `poly.txt` before the final solve. For example, `VI/agg.gms` contains the MCP formulation for `agg` and the matching polyhedral row information. The original GDX file is not required to run that exported model.

The batch generator skips non-LP instances and existing output files. Use `--select agg` to select an instance or `--overwrite` to rebuild exports. With `--verify`, it checks each model's poly writer in a temporary directory with the final solve disabled. Results are recorded in `VI/LINLib/generation_report.json`. See the [LINLib instructions](VI/LINLib/README.md) for filtering, fallback exports, and additional options.

Generate any missing LINLib model before selecting it for extraction. For example:

```bash
python3 VI/LINLib/generate_instances.py --select agg --verify
python3 extractProblem.py extract --type VI --select agg
```

The extractor requires the selected `.gms` file to exist; missing models produce an error with a suggestion to use the `list` command.

## PATHVI experiments

The PATHVI experiments compare three crash configurations: PNewton, Lemke ray start, and PATHVI ray start. First extract a model with VI structure, such as `bert_oc`, as shown above.

Create or edit `tempMCPs/path.opt` with one of the following configurations.

**PNewton**

```text
crash_method pnewton
```

**Lemke ray start**

```text
crash_method none
crash_perturb 0
lemke_start first
```

**PATHVI ray start**

```text
crash_method pathvi
pathvi_filename poly.txt
```

Run the extracted model with the configured PATH solver and enable its option file:

```bash
cd tempMCPs
gams bert_oc.gms mcp=path optfile=1
cd ..
```

This command assumes the intended PATH build is registered as `path` in GAMS. If it is registered under another solver name, use that name and its corresponding option filename.

The PATHVI configuration requires `poly.txt`, containing one polyhedral row name per line. For the standalone `bert_oc` example, the extracted `bert_oc.gms` writes this file before its solve statement. With the commands above, it is written to `tempMCPs/poly.txt`. Other models and reformulations must provide the matching row information in the working directory. The names must match the model being solved.

Run each configuration separately and compare the solution status, timings, and iteration counts in the GAMS listing and solver output. Additional examples are available under [`VI/`](VI/).

## Linear algebra basis package experiments

These experiments compare the solution times obtained with different basis factorization and update packages. Generate an MCP instance such as `bai_haung`, then select one method in `tempMCPs/path.opt`:

```text
factorization_method lusol
```

The thesis considers `lusol`, `blu_lusol`, `highs`, `conopt`, and `umfpack`. Use a PATH build that supports the selected method.

For UMFPACK, specify both the method and the path to the compiled basis library:

```text
factorization_method umfpack
factorization_library_name /absolute/path/to/compiled/umfpack_basis_library
```

Run the generated model with the option file enabled:

```bash
cd tempMCPs
gams bai_haung.gms mcp=path optfile=1
cd ..
```

Use the same instance, starting point, and other solver options when comparing packages. Preserve each run's listing or log before running the next configuration.

## Stochastic optimization experiments

These experiments use the Clear Lake stochastic optimization example to compare the Rockafellar–Uryasev and equilibrium formulations, as well as direct solution methods and decomposition algorithms. Solution times and PATH iteration counts are used to assess performance.

Starting from the repository root, change to the experiment directory and run the main GAMS script:

```bash
cd stochastic_optimization
gams clearlak-ecvarup_main.gms \
    --nstage=4 \
    --nchildren=3 \
    --randomSeed=1 \
    --experimentType=RU-PATH
```

| Option | Description | Default in the main script |
| --- | --- | --- |
| `--nstage` | Number of stages in the scenario tree. | `4` |
| `--nchildren` | Number of child nodes at each nonterminal node. | `3` |
| `--randomSeed` | Random seed used during data generation. | `1` |
| `--experimentType` | Formulation or solution method to run. | `checkSame` |
| `--iterationLimit` | Iteration limit used by the selected decomposition experiment. | `10` |

Common `--experimentType` values are `RU`, `RU-PATH`, `Equilibrium`, `PD-PATH`, `PD-PATH-LP`, and `PD-PATH-NLP`. The example explicitly selects `RU-PATH`; see the main script for additional choices and parameters.

The main files are:

- [`clearlak-ecvarup_main.gms`](stochastic_optimization/clearlak-ecvarup_main.gms): parameter defaults and experiment selection.
- [`clearlak-ecvarup_model.gms`](stochastic_optimization/clearlak-ecvarup_model.gms): shared variables, equations, data, and models.
- [`experiments/`](stochastic_optimization/experiments/): implementations of the solution methods.

## Stochastic equilibrium experiments

These experiments compare the success rates and solution times of algorithms based on risk decomposition for stochastic equilibrium problems.

Starting from the repository root, change to the experiment directory and run:

```bash
cd stochastic_equilibrium
gams main.gms \
    --data=tree3 \
    --randomSeed=1 \
    --quad=10 \
    --lambda=0.3 \
    --alpha=0.74 \
    --demandType=1 \
    --algorithm=PD-PATH
```

| Option | Description | Default |
| --- | --- | --- |
| `--data` | Scenario-tree dataset: `tree2` or `tree3`, loaded from the matching `.gdx` file. | `tree3` |
| `--randomSeed` | Random seed used during data generation. | `1` |
| `--quad` | Weight controlling the quadratic cost terms in the agents' objectives. | `10` |
| `--lambda` | Risk-aversion weight between expectation and CVaR; use a value in `[0, 1]`. | `0.3` |
| `--alpha` | CVaR confidence level; use a value in `[0, 1)` because the implementation divides by `1 - alpha`. | `0.74` |
| `--demandType` | Demand specification: `1`, `2`, or `3`. | `1` |
| `--algorithm` | Solution algorithm. | `PATH` |
| `--iterationLimit` | Iteration limit for the decomposition algorithms. | `100` |
| `--problemType` | Model variant; the example uses the original equilibrium model, `normal`. | `normal` |

The risk measure combines expectation and conditional value-at-risk:

$$
(1-\lambda)\mathbb{E}(\cdot) + \lambda\operatorname{CVaR}_{\alpha}(\cdot).
$$

For the default `normal` problem type, algorithm choices include `PATH`, `PATH-RN`, `PD`, `PD-PATH`, `PD-CC-PATH`, `PD-TrustRegion-PATH`, and `PD-LineSearch-PATH`. Additional algorithms and model variants are selected in [`main.gms`](stochastic_equilibrium/main.gms).

The main files are:

- [`main.gms`](stochastic_equilibrium/main.gms): experiment execution and algorithm selection.
- [`parameters.gms`](stochastic_equilibrium/parameters.gms): input parameters and their default values.
- [`data_dispatch.gms`](stochastic_equilibrium/data_dispatch.gms): data generation and scenario-tree loading.
- [`model_dispatch.gms`](stochastic_equilibrium/model_dispatch.gms): shared equilibrium models.
- [`algorithms/`](stochastic_equilibrium/algorithms/): implementations of the solution algorithms.
- [`FischerBurmeisterMacros/`](stochastic_equilibrium/FischerBurmeisterMacros/): residual evaluation for the demand specifications.

## Registering problem types and models

### Adding a type

Register a new type and create its folder with:

```bash
python3 extractProblem.py addType --type NCP
```

This adds `NCP` to the top-level `types` array in `problems.json` and creates `NCP/` beside the script. The folder includes an empty `.gitkeep` file so Git can track it before any models are added. An existing real directory with the same name can also be registered; its contents are preserved. Duplicate type names, including case variants, are rejected. Type names must start with a letter and contain only letters, digits, underscores, or hyphens.

The registry records empty types separately from their problems:

```json
{
  "types": ["MCP", "VI", "NCP"],
  "problems": []
}
```

The command preserves all existing problem records; the empty array above only illustrates the structure. A newly registered type has no listed problems until model files and corresponding problem records are added.

```bash
python3 extractProblem.py list --type NCP
```

Import and register a model under the new type, then extract it with the same command structure:

```bash
python3 extractProblem.py addProblem --type NCP --file /path/to/myProblem.gms
python3 extractProblem.py extract --type NCP --select myProblem
```

### Adding a problem

Import a `.gms` source file and register it with:

```bash
python3 extractProblem.py addProblem --type MCP --file /path/to/file/newProblem.gms
```

The type must already be registered. The filename determines the problem name: this example copies the file to `MCP/newProblem.gms` and adds its record to the `problems` array in [`problems.json`](problems.json). The original source is kept. Relative source paths are resolved from the directory where the command is run; destination paths are relative to the repository containing the script.

The problem is then available for listing and extraction:

```bash
python3 extractProblem.py list --type MCP
python3 extractProblem.py extract --type MCP --select newProblem
```

A file already in the intended type folder can be registered in place:

```bash
python3 extractProblem.py addProblem --type MCP --file MCP/myMCP.gms
```

Duplicate registrations within a type, including case variants, are rejected. Existing destination files are not overwritten; to register an existing unregistered model, pass that file's own path. If copying or saving the registry fails, the new copy is removed and existing files are preserved. The command imports only the specified file, so use standalone models or make their include/data dependencies available separately. Registration copies and records the source without compiling or solving it.

Each problem record contains its name without the `.gms` extension, its registered type, and its repository-relative source path. For example:

```json
{
  "name": "myMCP",
  "type": "MCP",
  "file": "MCP/myMCP.gms"
}
```

Each `(type, name)` pair must be unique, and `file` must match `<type>/<name>.gms`. A name can be registered separately under different types. Keep parameter defaults in the GAMS source. Removing an entry removes that problem from the listing without deleting its source file.

For a model that requires arguments with no defaults, add an optional `required_arguments` array to its record in `problems.json` after registration. Use command-line argument names without the leading `--`, for example:

```json
{
  "name": "myMCP",
  "type": "MCP",
  "file": "MCP/myMCP.gms",
  "required_arguments": ["dimension"]
}
```

`extractList` skips this model and warns users to extract it separately, for example with `extract --type MCP --select myMCP --dimension 20`. Omit the field or use an empty array for models that need no arguments or provide defaults for all parameters. Update this metadata if the model's input requirements change. `addProblem` preserves existing records and creates new records without required arguments; add this field when importing a model that needs user-supplied values.

The registry controls `list` and `extractList`. Single-model extraction continues to select an existing `.gms` file directly using `--type` and `--select`.

### MCP models

Add a standalone `.gms` file directly to `MCP/`. Its filename becomes the name used with `--select`. Include the variables, equations, complementarity pairings, starting point, and solve statement.

For a model with configurable size, use the GAMS parameter `%dimension%` and supply its value through `--dimension`. For example:

```gams
$if not setglobal dimension $setglobal dimension 10
set i /1*%dimension%/;

positive variable x(i);
equation f(i);

f(i).. x(i) - 1 =g= 0;
model myMCP /f.x/;

solve myMCP using mcp;
```

Save this example as `MCP/myMCP.gms`, then register and extract it from the repository root:

```bash
python3 extractProblem.py addProblem --type MCP --file MCP/myMCP.gms
python3 extractProblem.py extract --type MCP --select myMCP --dimension 20
```

### Models with VI structure

Add a standalone `.gms` file directly to `VI/`. For a VI already expressed as an MCP, include code that writes the polyhedral row names to `poly.txt` before the solve statement. For example, if the polyhedral equations are named `e3`, `e4`, `e5`, and `e6`:

```gams
file polystructure / 'poly.txt' /;
put polystructure;
put 'e3'/;
put 'e4'/;
put 'e5'/;
put 'e6'/;
putclose polystructure;
```

For indexed equations, write the names of the individual equation instances, as illustrated in [`VI/bert_oc.gms`](VI/bert_oc.gms). If EMP reformulates the model, the row names must correspond to the generated MCP. Add a dimension parameter only if the model supports varying its size.

Register and extract a newly added `VI/myVI.gms` model with:

```bash
python3 extractProblem.py addProblem --type VI --file VI/myVI.gms
python3 extractProblem.py extract --type VI --select myVI
```

## Outputs and reproducibility

GAMS normally writes a listing (`.lst`) alongside other generated files in the working directory. Inspect both the model status and solver status before comparing timings or iteration counts. Individual experiments may also display residuals, timing summaries, or generate additional data files.

Keep the same problem parameters and random seed to reproduce the generated data with the same implementation and software environment. For performance comparisons, record the GAMS and solver versions, experimental solver build, basis library, option files, and hardware. Some experiments generate or overwrite option files in their own directories; inspect the selected algorithm when changing solver settings.

## Extraction checks

Run the extraction unit tests with:

```bash
python3 -B -m unittest discover -s tests
```

To include integration checks with an installed, licensed GAMS executable:

```bash
python3 -B tests/test_extract_problem.py --gams-tests
```

The integration checks use temporary repositories to verify parameter expansion, failure handling, and preservation of an exported LP's polyhedral row writer.
