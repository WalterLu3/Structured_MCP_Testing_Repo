from typing import Optional
import random

def random_positive_probabilities(n: int, decimals: int = 2, rng: Optional[random.Random] = None):
    if n < 1:
        raise ValueError("n must be >= 1")
    S = 10 ** decimals
    if n > S:
        raise ValueError(f"Cannot guarantee >0 with {n} parts at {decimals} decimals")

    rng = rng or random

    stars_bars = [1] * (S - n) + [0] * (n - 1)
    rng.shuffle(stars_bars)

    parts, count = [], 0
    for x in stars_bars:
        if x == 1:
            count += 1
        else:
            parts.append(count)
            count = 0
    parts.append(count)

    return [(p + 1) / S for p in parts]

print(random_positive_probabilities(5))