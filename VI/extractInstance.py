import argparse
import subprocess
import sys
from pathlib import Path

# define the arguments to be parsed
def parse_arguments():
    parser = argparse.ArgumentParser(
        description="Generate MCP, VI, stochastic optimization, or stochastic equilibrium problems."
    )

    parser.add_argument(
        "--type",
        type=str,
        required=True,
        choices=[
            "MCP",
            "VI",
            "StochasticOptimization",
            "StochasticEquilibrium",
        ],
        help="Category of problem to generate.",
    )

    parser.add_argument(
        "--select",
        type=str,
        default=None,
        help="Name of the MCP or VI problem instance.",
    )

    parser.add_argument(
        "--dimension",
        type=int,
        default=None,
        help="Dimension of the selected MCP or VI problem.",
    )

    parser.add_argument(
        "--quad",
        type=str,
        default="",
        help="Weight of the quadratic term in the stage-cost function.",
    )

    return parser.parse_args()

if __name__ == "__main__":
    args = parse_arguments()

    # set up the base directory
    base_dir = Path(__file__).resolve().parent

    # Start preparing script
    fileName = args.select + ".gms"

    filePATH = base_dir / fileName

    if args.select.startswith("vimod"):

        gdxPath = base_dir / "vimod" / (str(args.select) + ".gdx")
        gdxPathLessExt = base_dir / "vimod" / str(args.select)
        vimodScriptPath = base_dir / "vimod"/ "vimod.gms"
        print(gdxPath)
        if gdxPath.exists():
            command = ["gams",
                       vimodScriptPath,
                       "--filename={GDX}".format(GDX=gdxPathLessExt)
                       ]

            subprocess.run(command, check=True)

            dump_file = base_dir.parent / "mcp_formulation.gms"
            temp_gms = base_dir.parent / "tempMCP.gms"

            dump_file.rename(temp_gms)   
            
    elif not filePATH.exists():
    # file does not exist as a standalone file
    # look into LINLIB
        print("File does not exist as a standalone file, look into LINLIB.")
        gdxPath = base_dir / "LINLIB" / "instances" / (args.select + ".gdx")

        lpScriptPath = base_dir / "LINLIB" / "generate_mcp_for_lp.gms"

        if gdxPath.exists():
            command = ["gams",
                       lpScriptPath,
                       "--iname={GDX}".format(GDX=gdxPath),
                       "--quad={quad}".format(quad=args.quad)
                       ]
            subprocess.run(command, check=True)

            dump_file = base_dir.parent / "mcp_formulation.gms"
            temp_gms = base_dir.parent / "tempMCP.gms"

            dump_file.rename(temp_gms)
    else:
        # Start preparing script
        command = [
            "gams", # python interpreter
            filePATH,
            "action=c",
            "dumpOpt=21",
        ]

        for name, value in vars(args).items():
            if name != "select":
                command += ["--{NAME}={VALUE}".format(NAME=name,VALUE=value)]

        #subprocess.run(command, check=True)

        subprocess.run(command, check=True)

        dump_file = base_dir.parent / (args.select + ".dmp")
        temp_gms = base_dir.parent / "tempMCP.gms"

        dump_file.rename(temp_gms)

