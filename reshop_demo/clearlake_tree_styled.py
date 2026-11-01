import matplotlib.pyplot as plt
from matplotlib.patches import Circle
from matplotlib.offsetbox import TextArea, HPacker, VPacker, AnnotationBbox
import math


def default_zero_dict():
    return {f"n{i}": 0.0 for i in range(1, 14)}


# ------------------------------------------------------------------
# Example data
# ------------------------------------------------------------------

f = default_zero_dict()
l = default_zero_dict()
r = default_zero_dict()
z = default_zero_dict()
riskprob = default_zero_dict()

f["n13"] = 50

l.update({
    "n1": 100,
    "n4": 150,
    "n7": 150,
    "n10": 150,
    "n12": 100,
    "n13": 250,
})

r.update({
    "n2": 50,
    "n3": 200,
    "n4": 200,
    "n5": 50,
    "n6": 150,
    "n7": 200,
    "n8": 50,
    "n9": 150,
    "n10": 200,
    "n11": 200,
    "n12": 200,
    "n13": 200,
})

riskprob.update({
    "n1": 1.000,
    "n2": 0.278,
    "n3": 0.445,
    "n4": 0.278,
    "n5": 0.278,
    "n6": 0.445,
    "n7": 0.278,
    "n8": 0.278,
    "n9": 0.445,
    "n10": 0.278,
    "n11": 0.175,
    "n12": 0.547,
    "n13": 0.278,
})


# ------------------------------------------------------------------
# Styling options
#
# Format:
#     "node": {"variable1", "variable2", ...}
#
# Valid variable names:
#     "f", "l", "r", "z", "y"
#
# You may put the same value in both dictionaries to make it
# BOTH bold and red.
# ------------------------------------------------------------------

bold_values = {
    # Examples:
    # "n13": {"f", "l"},
    # "n4": {"y"},
}

red_values = {
    # Examples:
    # "n13": {"f"},
    # "n2": {"y"},
}


def get_tree_structure():
    """
    Return node positions and edges for the 3-stage,
    13-node Clear Lake scenario tree.
    """

    positions = {
        "n1":  (0.0, 2.6),

        "n2":  (-2.4, 1.3),
        "n3":  ( 0.0, 1.3),
        "n4":  ( 2.4, 1.3),

        "n5":  (-3.2, 0.0),
        "n6":  (-2.4, 0.0),
        "n7":  (-1.6, 0.0),

        "n8":  (-0.8, 0.0),
        "n9":  ( 0.0, 0.0),
        "n10": ( 0.8, 0.0),

        "n11": ( 1.6, 0.0),
        "n12": ( 2.4, 0.0),
        "n13": ( 3.2, 0.0),
    }

    edges = [
        ("n1", "n2"), ("n1", "n3"), ("n1", "n4"),
        ("n2", "n5"), ("n2", "n6"), ("n2", "n7"),
        ("n3", "n8"), ("n3", "n9"), ("n3", "n10"),
        ("n4", "n11"), ("n4", "n12"), ("n4", "n13"),
    ]

    return positions, edges


def format_val(x):
    """
    Format values compactly for display inside each node.
    """

    if x is None:
        return "-"

    if abs(x) < 1e-12:
        return "0"

    if abs(x - round(x)) < 1e-10:
        return str(int(round(x)))

    return f"{x:.3f}"


def draw_edge(ax, p1, p2, radius):
    """
    Draw a black edge from the boundary of the parent circle
    to the boundary of the child circle.
    """

    x1, y1 = p1
    x2, y2 = p2

    dx = x2 - x1
    dy = y2 - y1

    distance = math.sqrt(dx**2 + dy**2)

    ux = dx / distance
    uy = dy / distance

    start_x = x1 + radius * ux
    start_y = y1 + radius * uy

    end_x = x2 - radius * ux
    end_y = y2 - radius * uy

    ax.plot(
        [start_x, end_x],
        [start_y, end_y],
        color="black",
        linewidth=1.5,
        zorder=1,
    )


def get_value_style(node, variable, bold_values, red_values):
    """
    Return text styling for one numerical value.
    """

    is_bold = variable in bold_values.get(node, set())
    is_red = variable in red_values.get(node, set())

    return {
        "fontsize": 7.5,
        "color": "red" if is_red else "black",
        "fontweight": "bold" if is_bold else "normal",
    }


def make_entry(node, variable, value, bold_values, red_values):
    """
    Create one entry such as:

        f=50

    The variable name and '=' stay black.
    Only the numerical value is styled.
    """

    prefix = TextArea(
        f"{variable}=",
        textprops={
            "fontsize": 7.5,
            "color": "black",
        },
    )

    number = TextArea(
        format_val(value),
        textprops=get_value_style(
            node,
            variable,
            bold_values,
            red_values,
        ),
    )

    return HPacker(
        children=[prefix, number],
        align="center",
        pad=0,
        sep=0,
    )


def make_node_label(
    node,
    f_val,
    l_val,
    r_val,
    z_val,
    y_val,
    bold_values,
    red_values,
):
    """
    Build a node label in the form:

          n7
       f=0, l=150
       r=200, z=0
         y=0.278

    Individual numerical values can be bold and/or red.
    """

    header = TextArea(
        node,
        textprops={
            "fontsize": 8,
            "fontweight": "normal",
            "color": "black",
        },
    )

    row1 = HPacker(
        children=[
            make_entry(node, "f", f_val, bold_values, red_values),
            TextArea(",  ", textprops={"fontsize": 7.5}),
            make_entry(node, "l", l_val, bold_values, red_values),
        ],
        align="center",
        pad=0,
        sep=0,
    )

    row2 = HPacker(
        children=[
            make_entry(node, "r", r_val, bold_values, red_values),
            TextArea(",  ", textprops={"fontsize": 7.5}),
            make_entry(node, "z", z_val, bold_values, red_values),
        ],
        align="center",
        pad=0,
        sep=0,
    )

    row3 = make_entry(
        node,
        "y",
        y_val,
        bold_values,
        red_values,
    )

    return VPacker(
        children=[header, row1, row2, row3],
        align="center",
        pad=0,
        sep=1,
    )


def draw_clearlake_tree(
    f_vals=None,
    l_vals=None,
    r_vals=None,
    z_vals=None,
    riskprob_vals=None,
    bold_values=None,
    red_values=None,
    title="Clear Lake Tree",
    figsize=(11, 7),
    save_path=None,
    show=True,
):
    """
    Draw the Clear Lake scenario tree.

    Styling examples:

        bold_values = {
            "n13": {"f", "l"},
            "n4": {"y"},
        }

        red_values = {
            "n13": {"f"},
            "n2": {"y"},
        }

    If a value appears in both dictionaries, it will be
    both bold and red.
    """

    if f_vals is None:
        f_vals = default_zero_dict()

    if l_vals is None:
        l_vals = default_zero_dict()

    if r_vals is None:
        r_vals = default_zero_dict()

    if z_vals is None:
        z_vals = default_zero_dict()

    if riskprob_vals is None:
        riskprob_vals = default_zero_dict()

    if bold_values is None:
        bold_values = {}

    if red_values is None:
        red_values = {}

    positions, edges = get_tree_structure()

    fig, ax = plt.subplots(figsize=figsize)

    radius = 0.40

    # Draw edges first.
    for parent, child in edges:
        draw_edge(
            ax,
            positions[parent],
            positions[child],
            radius,
        )

    # Draw nodes and labels.
    for node, (x, y_coord) in positions.items():

        circle = Circle(
            (x, y_coord),
            radius=radius,
            facecolor="white",
            edgecolor="black",
            linewidth=1.5,
            zorder=2,
        )

        ax.add_patch(circle)

        label_box = make_node_label(
            node=node,
            f_val=f_vals.get(node, 0.0),
            l_val=l_vals.get(node, 0.0),
            r_val=r_vals.get(node, 0.0),
            z_val=z_vals.get(node, 0.0),
            y_val=riskprob_vals.get(node, 0.0),
            bold_values=bold_values,
            red_values=red_values,
        )

        annotation = AnnotationBbox(
            label_box,
            (x, y_coord),
            frameon=False,
            box_alignment=(0.5, 0.5),
        )
        
        annotation.set_zorder(3)

        ax.add_artist(annotation)

    ax.set_title(title, fontsize=15)

    ax.set_xlim(-3.8, 3.8)
    ax.set_ylim(-0.6, 3.15)

    ax.set_aspect("equal")
    ax.axis("off")

    plt.tight_layout()

    if save_path is not None:
        plt.savefig(
            save_path,
            dpi=300,
            bbox_inches="tight",
        )

    if show:
        plt.show()
    else:
        plt.close(fig)


if __name__ == "__main__":

    # --------------------------------------------------------------
    # Example styling
    #
    # n13's f value will be bold AND red.
    # n13's l value will be bold.
    # n2's y value will be red.
    # n4's y value will be bold.
    #
    # Delete or modify these entries however you want.
    # --------------------------------------------------------------

    bold_values = {
        "n13": {"f", "l"},
        "n4": {"y"},
    }

    red_values = {
        "n13": {"f"},
        "n2": {"y"},
    }

    draw_clearlake_tree(
        f_vals=f,
        l_vals=l,
        r_vals=r,
        z_vals=z,
        riskprob_vals=riskprob,
        bold_values=bold_values,
        red_values=red_values,
        title="After D Step 2",
        save_path="clearlake_tree.png",
    )
