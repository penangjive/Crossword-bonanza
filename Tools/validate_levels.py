#!/usr/bin/env python3
"""Validate CrosswordBonanza/Resources/levels.json.

This is deliberately written independently of generate_levels.py -- it re-derives
every grid from the raw JSON rather than trusting the generator's bookkeeping.
It is the only automated correctness check this project has, because the Swift
side cannot be compiled or run in the environment the data was authored in.

Exits non-zero and prints every problem found.

Usage:  python3 Tools/validate_levels.py [PATH]
"""

import collections
import json
import os
import sys

ACROSS = "across"
DOWN = "down"

TIER_RULES = {
    # tier: (min word length, max word length, needs an emoji picture clue)
    1: (3, 4, True),
    2: (3, 6, True),
    3: (4, 8, False),
}

DEFAULT_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "CrosswordBonanza",
    "Resources",
    "levels.json",
)


def cells_for(entry):
    word, row, col = entry["word"], entry["row"], entry["col"]
    if entry["direction"] == ACROSS:
        return [(row, col + i) for i in range(len(word))]
    return [(row + i, col) for i in range(len(word))]


def check_level(level, problems):
    tag = f"level {level.get('id', '?')}"
    required = {"id", "tier", "rows", "cols", "entries"}
    missing = required - set(level)
    if missing:
        problems.append(f"{tag}: missing keys {sorted(missing)}")
        return

    rows, cols, tier = level["rows"], level["cols"], level["tier"]
    if tier not in TIER_RULES:
        problems.append(f"{tag}: unknown tier {tier}")
        return
    min_len, max_len, needs_emoji = TIER_RULES[tier]

    entries = level["entries"]
    if len(entries) < 2:
        problems.append(f"{tag}: needs at least 2 words, has {len(entries)}")

    grid = {}
    seen_words = set()
    seen_emoji = set()
    placements = set()

    for entry in entries:
        word = entry["word"]
        if not word.isalpha() or not word.isupper():
            problems.append(f"{tag}: word {word!r} is not plain uppercase A-Z")
        if word in seen_words:
            problems.append(f"{tag}: word {word} appears twice in one puzzle")
        seen_words.add(word)

        if not min_len <= len(word) <= max_len:
            problems.append(
                f"{tag}: {word} is {len(word)} letters, tier {tier} allows {min_len}-{max_len}"
            )
        if entry["direction"] not in (ACROSS, DOWN):
            problems.append(f"{tag}: {word} has bad direction {entry['direction']!r}")
            continue

        key = (entry["row"], entry["col"], entry["direction"])
        if key in placements:
            problems.append(f"{tag}: two entries start at {key}")
        placements.add(key)

        if not entry.get("clue"):
            problems.append(f"{tag}: {word} has no clue")
        if not entry.get("spoken"):
            problems.append(f"{tag}: {word} has nothing for the narrator to say")
        if needs_emoji and not entry.get("emoji"):
            problems.append(f"{tag}: {word} needs a picture clue at tier {tier}")
        emoji = entry.get("emoji")
        if emoji:
            if emoji in seen_emoji:
                problems.append(f"{tag}: picture clue {emoji} used by two words")
            seen_emoji.add(emoji)
        if word.lower() in entry.get("clue", "").lower():
            problems.append(f"{tag}: clue for {word} contains the answer")

        cells = cells_for(entry)
        for (r, c), letter in zip(cells, word):
            if not (0 <= r < rows and 0 <= c < cols):
                problems.append(f"{tag}: {word} runs outside the {rows}x{cols} grid")
                break
            existing = grid.get((r, c))
            if existing is not None and existing != letter:
                problems.append(
                    f"{tag}: {word} wants {letter} at ({r},{c}) but {existing} is already there"
                )
            grid[(r, c)] = letter

    # The bounding box must be tight: a fully empty edge row or column means the
    # grid renders with dead space and undersized cells.
    if grid:
        if min(r for r, _ in grid) != 0 or max(r for r, _ in grid) != rows - 1:
            problems.append(f"{tag}: rows={rows} does not match the occupied cells")
        if min(c for _, c in grid) != 0 or max(c for _, c in grid) != cols - 1:
            problems.append(f"{tag}: cols={cols} does not match the occupied cells")

    # No word may butt directly into another in its own direction, and a cell
    # that isn't a crossing may not have a sideways neighbour -- either would
    # create an unclued word in the grid that the player can see but not solve.
    crossing_cells = collections.Counter()
    for entry in entries:
        for cell in cells_for(entry):
            crossing_cells[cell] += 1

    for entry in entries:
        word = entry["word"]
        cells = cells_for(entry)
        if not cells:
            continue
        head, tail = cells[0], cells[-1]
        if entry["direction"] == ACROSS:
            outside = [(head[0], head[1] - 1), (tail[0], tail[1] + 1)]
        else:
            outside = [(head[0] - 1, head[1]), (tail[0] + 1, tail[1])]
        for cell in outside:
            if cell in grid:
                problems.append(f"{tag}: {word} runs straight into the letter at {cell}")
        for cell in cells:
            if crossing_cells[cell] > 1:
                continue  # a genuine crossing, sideways neighbours are expected
            r, c = cell
            sides = [(r - 1, c), (r + 1, c)] if entry["direction"] == ACROSS else [(r, c - 1), (r, c + 1)]
            for side in sides:
                if side in grid:
                    problems.append(
                        f"{tag}: {word} sits alongside the letter at {side}, making an unclued word"
                    )

    # Every word must be reachable from every other through shared cells,
    # otherwise the puzzle is two disconnected puzzles sharing a screen.
    if entries:
        adjacency = collections.defaultdict(set)
        cell_owners = collections.defaultdict(list)
        for index, entry in enumerate(entries):
            for cell in cells_for(entry):
                cell_owners[cell].append(index)
        for owners in cell_owners.values():
            for a in owners:
                for b in owners:
                    if a != b:
                        adjacency[a].add(b)
        reached = {0}
        stack = [0]
        while stack:
            current = stack.pop()
            for neighbour in adjacency[current]:
                if neighbour not in reached:
                    reached.add(neighbour)
                    stack.append(neighbour)
        if len(reached) != len(entries):
            orphans = [entries[i]["word"] for i in range(len(entries)) if i not in reached]
            problems.append(f"{tag}: {', '.join(orphans)} do not connect to the rest of the grid")


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_PATH
    with open(path, encoding="utf-8") as handle:
        payload = json.load(handle)

    problems = []
    levels = payload.get("levels", [])
    if len(levels) < 1:
        problems.append("no levels at all")

    ids = [level.get("id") for level in levels]
    if ids != list(range(1, len(levels) + 1)):
        problems.append(f"level ids must run 1..{len(levels)} in order, got {ids}")

    for level in levels:
        check_level(level, problems)

    # The whole point of the ladder: it must never get easier as you go.
    previous_words = 0
    previous_tier = 0
    for level in levels:
        count = len(level.get("entries", []))
        if count < previous_words:
            problems.append(
                f"level {level.get('id')}: drops to {count} words after {previous_words} -- "
                "the ladder must never get easier"
            )
        if level.get("tier", 0) < previous_tier:
            problems.append(f"level {level.get('id')}: tier goes backwards")
        previous_words = max(previous_words, count)
        previous_tier = max(previous_tier, level.get("tier", 0))

    for problem in problems:
        print("FAIL:", problem)

    total_words = sum(len(level.get("entries", [])) for level in levels)
    unique = {e["word"] for level in levels for e in level.get("entries", [])}
    print(
        f"\n{len(levels)} levels, {total_words} placed words, {len(unique)} distinct words, "
        f"{len(problems)} problems"
    )
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
