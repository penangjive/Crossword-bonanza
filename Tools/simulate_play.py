#!/usr/bin/env python3
"""Play every level through a faithful copy of the Swift cursor logic.

`PuzzleEngine.swift` cannot be compiled or run in the environment this data was
built in, so its cursor rules -- advance within a word, jump to the next
unfinished word, skip cells that are already correct -- are re-implemented here
and exercised against all 30 real levels.

What this proves: every puzzle can be driven to completion by a player who only
ever types the correct letter, with no cell left unreachable and no state the
cursor can get stuck in. What it does not prove: that the Swift compiles. Keep
this file in step with PuzzleEngine.swift by hand.

Usage:  python3 Tools/simulate_play.py
"""

import json
import os
import sys

ACROSS = "across"

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


class Engine:
    """Mirrors PuzzleEngine. Keep the method names the same as the Swift."""

    def __init__(self, level):
        self.entries = level["entries"]
        self.cells = [cells_for(entry) for entry in self.entries]
        self.solution = {}
        for entry, cells in zip(self.entries, self.cells):
            for cell, letter in zip(cells, entry["word"]):
                self.solution[cell] = letter
        self.filled = {}
        self.solved_ids = set()
        self.selected = 0
        self.cursor = 0
        self.hints_used = 0
        self.is_solved = False

    # -- geometry -------------------------------------------------------

    def entry_id(self, index):
        entry = self.entries[index]
        return (entry["row"], entry["col"], entry["direction"])

    def current_cell(self):
        cells = self.cells[self.selected]
        return cells[min(self.cursor, len(cells) - 1)]

    def entry_indices_containing(self, cell):
        return [i for i, cells in enumerate(self.cells) if cell in cells]

    def first_blank_index(self, index, start=0):
        cells = self.cells[index]
        for i in range(start, len(cells)):
            if cells[i] not in self.filled:
                return i
        return None

    # -- play -----------------------------------------------------------

    def type_letter(self, letter):
        if self.is_solved:
            return "ignored"
        cell = self.current_cell()
        if cell in self.filled:
            self.advance_cursor()
            return "ignored"
        if self.solution[cell] != letter:
            return "wrong"
        self.place(letter, cell)
        return "correct"

    def use_hint(self):
        if self.is_solved:
            return "ignored"
        index = self.first_blank_index(self.selected)
        if index is not None:
            cell = self.cells[self.selected][index]
            self.cursor = index
        else:
            blanks = [c for c in self.solution if c not in self.filled]
            if not blanks:
                return "ignored"
            cell = blanks[0]
        self.hints_used += 1
        self.place(self.solution[cell], cell)
        return "correct"

    def place(self, letter, cell):
        self.filled[cell] = letter

        completed = None
        for index in self.entry_indices_containing(cell):
            key = self.entry_id(index)
            if key in self.solved_ids:
                continue
            if all(c in self.filled for c in self.cells[index]):
                self.solved_ids.add(key)
                if completed is None or index == self.selected:
                    completed = index

        if len(self.filled) == len(self.solution):
            self.is_solved = True
            return

        if completed is not None and self.entry_id(completed) == self.entry_id(self.selected):
            self.select_next_entry()
        else:
            self.advance_cursor()

    def advance_cursor(self):
        nxt = self.first_blank_index(self.selected, self.cursor + 1)
        if nxt is not None:
            self.cursor = nxt
            return
        wrapped = self.first_blank_index(self.selected)
        if wrapped is not None:
            self.cursor = wrapped
            return
        self.select_next_entry()

    def select_next_entry(self):
        total = len(self.entries)
        for step in range(1, total + 1):
            candidate = (self.selected + step) % total
            if self.entry_id(candidate) not in self.solved_ids:
                self.selected = candidate
                self.cursor = self.first_blank_index(candidate) or 0
                return

    def stars(self):
        if self.hints_used == 0:
            return 3
        if self.hints_used <= 2:
            return 2
        return 1


def play(level, problems, use_hints_only=False):
    engine = Engine(level)
    tag = f"level {level['id']}"
    budget = len(engine.solution) * 12 + 200

    for _ in range(budget):
        if engine.is_solved:
            break
        if use_hints_only:
            if engine.use_hint() == "ignored":
                problems.append(f"{tag}: hints stopped working before the puzzle was solved")
                return engine
            continue

        cell = engine.current_cell()
        if cell in engine.filled:
            # The cursor should never park on a solved cell; typing recovers,
            # but it means advance_cursor left it somewhere it should not.
            engine.advance_cursor()
            continue
        engine.type_letter(engine.solution[cell])
    else:
        problems.append(f"{tag}: did not finish within {budget} steps -- the cursor is stuck")
        return engine

    if not engine.is_solved:
        problems.append(f"{tag}: ended unsolved")
    if len(engine.filled) != len(engine.solution):
        missing = len(engine.solution) - len(engine.filled)
        problems.append(f"{tag}: {missing} cells were never reachable by the cursor")
    if len(engine.solved_ids) != len(engine.entries):
        problems.append(f"{tag}: finished with words still marked unsolved")
    return engine


def main():
    path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_PATH
    with open(path, encoding="utf-8") as handle:
        levels = json.load(handle)["levels"]

    problems = []

    for level in levels:
        # A player who never makes a mistake earns three stars.
        clean = play(level, problems)
        if clean.is_solved and clean.stars() != 3:
            problems.append(f"level {level['id']}: a flawless run did not earn 3 stars")

        # A player who only ever presses the hint button must still finish, and
        # must land on one star. This is the "child gives up and taps hint over
        # and over" path, and it has to terminate.
        hinted = play(level, problems, use_hints_only=True)
        if hinted.is_solved and hinted.stars() != 1:
            problems.append(f"level {level['id']}: an all-hints run did not end on 1 star")

        # Wrong letters must change nothing at all.
        engine = Engine(level)
        before = (dict(engine.filled), engine.selected, engine.cursor)
        cell = engine.current_cell()
        wrong = "Z" if engine.solution[cell] != "Z" else "Q"
        if engine.type_letter(wrong) != "wrong":
            problems.append(f"level {level['id']}: a wrong letter was accepted")
        after = (dict(engine.filled), engine.selected, engine.cursor)
        if before != after:
            problems.append(f"level {level['id']}: a wrong letter changed the board state")

    for problem in problems:
        print("FAIL:", problem)
    print(f"\nsimulated {len(levels)} levels three ways: {len(problems)} problems")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
