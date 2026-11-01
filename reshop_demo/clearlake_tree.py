import matplotlib.pyplot as plt
from matplotlib.patches import Circle
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

    # Start at parent-circle boundary
    start_x = x1 + radius * ux
    start_y = y1 + radius * uy

    # End at child-circle boundary
    end_x = x2 - radius * ux
    end_y = y2 - radius * uy

    ax.plot(
        [start_x, end_x],
        [start_y, end_y],
        color="black",
        linewidth=1.5,
        zorder=1,
    )


def draw_clearlake_tree(
    f_vals=None,
    l_vals=None,
    r_vals=None,
    z_vals=None,
    riskprob_vals=None,
    title="Clear Lake Tree",
    figsize=(11, 7),
    save_path=None,
    show=True,
):
    """
    Draw the Clear Lake scenario tree.

    Each node displays:
        node name
        f, l
        r, z
        y  (risk probability)
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

    positions, edges = get_tree_structure()

    fig, ax = plt.subplots(figsize=figsize)

    # Radius of each circular node
    radius = 0.40

    # Draw edges first
    for parent, child in edges:
        draw_edge(
            ax,
            positions[parent],
            positions[child],
            radius,
        )

    # Draw nodes
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

        label = (
            f"{node}\n"
            f"f={format_val(f_vals.get(node, 0.0))}, "
            f"l={format_val(l_vals.get(node, 0.0))}\n"
            f"r={format_val(r_vals.get(node, 0.0))}, "
            f"z={format_val(z_vals.get(node, 0.0))}\n"
            f"y={format_val(riskprob_vals.get(node, 0.0))}"
        )

        ax.text(
            x,
            y_coord,
            label,
            ha="center",
            va="center",
            fontsize=7.5,
            zorder=3,
        )

    ax.set_title(title, fontsize=15)

    # Compact horizontal layout
    ax.set_xlim(-3.8, 3.8)
    ax.set_ylim(-0.6, 3.15)

    # Preserve circular node shapes
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

    draw_clearlake_tree(
        f_vals=f,
        l_vals=l,
        r_vals=r,
        z_vals=z,
        riskprob_vals=riskprob,
        title="After D Step 2",
        save_path="clearlake_tree.png",
    )
