# Installing PATHVICRASH on macOS

These files provide the experimental PATH solver with the PATHVI crash method for macOS on Apple Silicon (`arm64`). Use an `arm64` GAMS installation.

## 1. Copy the solver files

Copy the following files from this directory:

- `libptwcclib64.dylib`
- `libpath51.dylib`
- `optpath_pathvi.def`
- `gamsconfig.yaml`

into:

```text
/Users/<user>/Library/Preferences/GAMS/
```

Here, `<user>` is your macOS account name. Run `whoami` in Terminal to find it. Create the destination folder if it does not exist.

The `optpath_pathvi.def` file is needed because the supplied configuration references it through `defName`. If the destination already contains a `gamsconfig.yaml`, add the supplied `PATHVICRASH` entry to its `solverConfig` list, preserving any existing settings.

## 2. Update the account name

Open `/Users/<user>/Library/Preferences/GAMS/gamsconfig.yaml` in a text editor. Replace `<user>` in both `defName` and `library.libName` with your account name, keeping the existing indentation and other settings.

For example, for an account named `alice`, the paths should be:

```yaml
defName: /Users/alice/Library/Preferences/GAMS/optpath_pathvi.def
library:
  libName: /Users/alice/Library/Preferences/GAMS/libptwcclib64.dylib
```

GAMS reads this user configuration when a new run starts and registers the MCP solver as `pathvicrash`.

## 3. Run a model with PATHVICRASH

Select the solver with:

```bash
gams your_model.gms mcp=pathvicrash
```

To use the PATHVI crash method, create `pathvicrash.opt` in the model's working directory with:

```text
crash_method pathvi
pathvi_filename poly.txt
```

Then enable the option file:

```bash
gams your_model.gms mcp=pathvicrash optfile=1
```

The matching `poly.txt` must be available when the solver runs. The repository's standalone `VI/bert_oc.gms` model writes this file before solving. For example, from the repository root:

```bash
python3 extractProblem.py extract --type VI --select bert_oc
```

Save the option file above as `tempMCPs/pathvicrash.opt`, then run:

```bash
cd tempMCPs
gams bert_oc.gms mcp=pathvicrash optfile=1
cd ..
```

See the GAMS documentation on [macOS configuration directories](https://www.gams.com/latest/docs/UG_STANDARD_LOCATIONS.html) and [registering external solvers](https://www.gams.com/latest/docs/UG_GamsCall.html#UG_GamsCall_AddingSolversViaGamsconfigyaml) for details.
