#!/usr/bin/env python3
"""Generate CrosswordBonanza/Resources/levels.json.

Packs words from word_bank.py into sparse crossword grids, one per level,
following a fixed difficulty ramp. Deterministic: a fixed RNG seed per level
means re-running this produces byte-identical output.

Placement obeys standard crossword adjacency rules, so the grid can never
contain an accidental two-letter word running alongside a placed one:

  * every cell of a word is in bounds
  * the cell immediately before the start and after the end must be empty
  * a cell that crosses an existing word must carry the same letter
  * a cell that does NOT cross must have both perpendicular neighbours empty

Usage:  python3 Tools/generate_levels.py [--out PATH]
"""

import argparse
import json
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from word_bank import by_length, validate_bank  # noqa: E402

ACROSS = "across"
DOWN = "down"

# id, tier, grid size, number of words, allowed word lengths.
# Word count and grid size never decrease, which is what makes the ladder
# monotonically harder; validate_levels.py enforces that independently.
LEVEL_SPECS = [
    # Tier 1 -- picture clues only, 3-4 letter words, tiny grids.
    (1, 1, 5, 2, (3, 3)),
    (2, 1, 5, 2, (3, 4)),
    (3, 1, 5, 3, (3, 3)),
    (4, 1, 5, 3, (3, 4)),
    (5, 1, 5, 3, (3, 4)),
    (6, 1, 5, 4, (3, 4)),
    (7, 1, 5, 4, (3, 4)),
    (8, 1, 5, 4, (3, 4)),
    (9, 1, 5, 4, (3, 4)),
    (10, 1, 5, 5, (3, 4)),
    # Tier 2 -- emoji shrinks, text clues appear, words grow.
    (11, 2, 6, 5, (3, 5)),
    (12, 2, 6, 5, (3, 5)),
    (13, 2, 6, 5, (4, 5)),
    (14, 2, 6, 6, (3, 5)),
    (15, 2, 6, 6, (3, 5)),
    (16, 2, 6, 6, (4, 5)),
    (17, 2, 6, 6, (4, 6)),
    (18, 2, 6, 6, (4, 6)),
    (19, 2, 6, 6, (4, 6)),
    (20, 2, 6, 6, (4, 6)),
    # Tier 3 -- text clues only, real crosswords.
    (21, 3, 7, 6, (4, 7)),
    (22, 3, 7, 6, (4, 7)),
    (23, 3, 7, 7, (4, 7)),
    (24, 3, 7, 7, (4, 7)),
    (25, 3, 7, 7, (4, 7)),
    (26, 3, 8, 7, (5, 8)),
    (27, 3, 8, 8, (4, 8)),
    (28, 3, 8, 8, (4, 8)),
    (29, 3, 8, 8, (5, 8)),
    (30, 3, 8, 9, (4, 8)),
]

MAX_ATTEMPTS = 4000


def cells_for(word, row, col, direction):
    if direction == ACROSS:
        return [(row, col + i) for i in range(len(word))]
    return [(row + i, col) for i in range(len(word))]


def crossings_if_placed(grid, size, word, row, col, direction):
    """Return the number of crossings, or None if the placement is illegal."""
    cells = cells_for(word, row, col, direction)
    for r, c in cells:
        if not (0 <= r < size and 0 <= c < size):
            return None

    # The squares just outside each end must be empty, or the placed word
    # would run straight into an existing one and make a longer nonsense word.
    head_r, head_c = cells[0]
    tail_r, tail_c = cells[-1]
    if direction == ACROSS:
        before, after = (head_r, head_c - 1), (tail_r, tail_c + 1)
    else:
        before, after = (head_r - 1, head_c), (tail_r + 1, tail_c)
    if before in grid or after in grid:
        return None

    crossings = 0
    for (r, c), letter in zip(cells, word):
        existing = grid.get((r, c))
        if existing is not None:
            if existing != letter:
                return None
            crossings += 1
            continue
        # A fresh cell must not sit beside another word sideways-on.
        sides = [(r - 1, c), (r + 1, c)] if direction == ACROSS else [(r, c - 1), (r, c + 1)]
        if any(side in grid for side in sides):
            return None
    return crossings


def try_build(spec, rng):
    """One attempt at packing a level. Returns placements or None."""
    _, _, size, want_words, (min_len, max_len) = spec

    buckets = by_length()
    pool = []
    for length in range(min_len, max_len + 1):
        pool.extend(buckets.get(length, []))
    if len(pool) < want_words:
        return None
    rng.shuffle(pool)

    grid = {}
    placements = []
    used_words = set()

    # Seed the grid with a long word, roughly centred, so later words have
    # room to hang off it in both directions.
    seed_candidates = [w for w in pool if len(w[0]) <= size]
    if not seed_candidates:
        return None
    seed = max(seed_candidates[:12], key=lambda w: len(w[0]))
    seed_dir = rng.choice([ACROSS, DOWN])
    offset = (size - len(seed[0])) // 2
    seed_row = rng.randrange(size) if seed_dir == ACROSS else offset
    seed_col = offset if seed_dir == ACROSS else rng.randrange(size)
    if crossings_if_placed(grid, size, seed[0], seed_row, seed_col, seed_dir) is None:
        return None
    for (r, c), letter in zip(cells_for(seed[0], seed_row, seed_col, seed_dir), seed[0]):
        grid[(r, c)] = letter
    placements.append({"entry": seed, "row": seed_row, "col": seed_col, "dir": seed_dir})
    used_words.add(seed[0])

    # Index the pool by letter so we only consider words that could actually
    # cross an occupied square, instead of scanning every word at every cell.
    by_letter = {}
    for entry in pool:
        for index, letter in enumerate(entry[0]):
            by_letter.setdefault(letter, []).append((entry, index))

    while len(placements) < want_words:
        best = None
        for (anchor_r, anchor_c), anchor_letter in list(grid.items()):
            for entry, index in by_letter.get(anchor_letter, ()):
                word = entry[0]
                if word in used_words:
                    continue
                for direction in (ACROSS, DOWN):
                    if direction == ACROSS:
                        row, col = anchor_r, anchor_c - index
                    else:
                        row, col = anchor_r - index, anchor_c
                    crossings = crossings_if_placed(grid, size, word, row, col, direction)
                    if crossings is None or crossings == 0:
                        continue  # every word after the first must connect
                    # Prefer more crossings (denser, more satisfying grids),
                    # then longer words, then a small random nudge so
                    # different seeds explore different shapes.
                    score = crossings * 100 + len(word) * 5 + rng.random()
                    if best is None or score > best[0]:
                        best = (score, entry, row, col, direction)
        if best is None:
            return None
        _, entry, row, col, direction = best
        for (r, c), letter in zip(cells_for(entry[0], row, col, direction), entry[0]):
            grid[(r, c)] = letter
        placements.append({"entry": entry, "row": row, "col": col, "dir": direction})
        used_words.add(entry[0])

    return placements


def build_level(spec):
    level_id, tier, size, want_words, _ = spec
    for attempt in range(MAX_ATTEMPTS):
        rng = random.Random(level_id * 100_003 + attempt)
        placements = try_build(spec, rng)
        if placements is None:
            continue
        # Deterministic, human-readable ordering: top-to-bottom, left-to-right,
        # across before down -- the same order the numbering will run in.
        placements.sort(key=lambda p: (p["row"], p["col"], p["dir"] != ACROSS))

        # Crop to the bounding box so an easy two-word level isn't rendered as
        # a mostly-empty 5x5 -- the cells can then be drawn much bigger.
        occupied = [
            cell
            for p in placements
            for cell in cells_for(p["entry"][0], p["row"], p["col"], p["dir"])
        ]
        top = min(r for r, _ in occupied)
        left = min(c for _, c in occupied)
        rows = max(r for r, _ in occupied) - top + 1
        cols = max(c for _, c in occupied) - left + 1

        entries = []
        for p in placements:
            p["row"] -= top
            p["col"] -= left
            word, emoji, clue = p["entry"]
            entries.append(
                {
                    "word": word,
                    "row": p["row"],
                    "col": p["col"],
                    "direction": p["dir"],
                    "emoji": emoji,
                    "clue": clue,
                    # Tier 1 players cannot read, so the narrator simply names
                    # the picture. From tier 2 the narrator reads the clue.
                    "spoken": word.capitalize() if tier == 1 else clue,
                }
            )
        return {"id": level_id, "tier": tier, "rows": rows, "cols": cols, "entries": entries}
    raise SystemExit(
        f"level {level_id}: could not pack {want_words} words into {size}x{size} "
        f"after {MAX_ATTEMPTS} attempts -- loosen its LEVEL_SPECS row"
    )


def render(level):
    """ASCII art for a level, for eyeballing the output."""
    grid = [["." for _ in range(level["cols"])] for _ in range(level["rows"])]
    for entry in level["entries"]:
        r, c = entry["row"], entry["col"]
        for i, letter in enumerate(entry["word"]):
            if entry["direction"] == ACROSS:
                grid[r][c + i] = letter
            else:
                grid[r + i][c] = letter
    return "\n".join(" ".join(row) for row in grid)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--out",
        default=os.path.join(
            os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
            "CrosswordBonanza",
            "Resources",
            "levels.json",
        ),
    )
    parser.add_argument("--show", action="store_true", help="print each grid")
    args = parser.parse_args()

    problems = validate_bank()
    if problems:
        for problem in problems:
            print("word bank problem:", problem, file=sys.stderr)
        raise SystemExit("fix the word bank first")

    levels = [build_level(spec) for spec in LEVEL_SPECS]
    payload = {"version": 1, "levels": levels}

    os.makedirs(os.path.dirname(args.out), exist_ok=True)
    with open(args.out, "w", encoding="utf-8") as handle:
        json.dump(payload, handle, ensure_ascii=False, indent=2)
        handle.write("\n")

    for level in levels:
        words = " ".join(e["word"] for e in level["entries"])
        print(f"level {level['id']:>2} tier {level['tier']} {level['rows']}x{level['cols']} "
              f"{len(level['entries'])} words: {words}")
        if args.show:
            print(render(level))
            print()
    print(f"\nwrote {len(levels)} levels to {args.out}")


if __name__ == "__main__":
    main()
