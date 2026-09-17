#!/usr/bin/env python3
"""Generate CrosswordBonanza.swiftpm from CrosswordBonanza/.

Swift Playgrounds on iPad can open a `.swiftpm` app package and build and run it
on the device. It cannot open a `.xcodeproj`. So this script mirrors the app
sources into a Swift Playgrounds package, letting someone with an iPad and no Mac
build the game.

`CrosswordBonanza/` stays the single source of truth. The mirror is generated,
committed (so it can be downloaded and opened with no tooling at all), and kept
honest by `--check`, which fails if the two ever drift apart.

What is mirrored:
  * every .swift file, at the same relative path
  * Resources/levels.json
What is not:
  * Assets.xcassets -- Swift Playgrounds takes the icon and accent colour from
    Package.swift, and no code references an asset by name.

Usage:
    python3 Tools/make_swiftpm.py            # (re)generate
    python3 Tools/make_swiftpm.py --check    # verify in sync, exit 1 on drift
"""

import argparse
import filecmp
import os
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE = os.path.join(ROOT, "CrosswordBonanza")
TARGET = os.path.join(ROOT, "CrosswordBonanza.swiftpm")

RESOURCE_FILES = [os.path.join("Resources", "levels.json")]

# `import AppleProductTypes` only resolves inside Swift Playgrounds and Xcode's
# Playgrounds SDK. This manifest is not meant for plain `swift build`.
PACKAGE_SWIFT = '''// swift-tools-version: 5.9

// GENERATED FILE -- do not edit.
// Regenerate with: python3 Tools/make_swiftpm.py
//
// This is the Swift Playgrounds build of Crossword Bonanza, for building the
// game on an iPad. The sources here are copies; CrosswordBonanza/ is the
// source of truth and CrosswordBonanza.xcodeproj is the primary project.

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "CrosswordBonanza",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .iOSApplication(
            name: "CrosswordBonanza",
            targets: ["AppModule"],
            bundleIdentifier: "com.crosswordbonanza.game",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .sparkle),
            accentColor: .presetColor(.yellow),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: ".",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
'''


def swift_sources():
    """Every .swift file under CrosswordBonanza/, as relative paths."""
    found = []
    for dirpath, dirnames, filenames in os.walk(SOURCE):
        dirnames[:] = sorted(d for d in dirnames if not d.endswith(".xcassets"))
        for name in sorted(filenames):
            if name.endswith(".swift"):
                full = os.path.join(dirpath, name)
                found.append(os.path.relpath(full, SOURCE))
    return sorted(found)


def planned_files():
    """{relative path inside the package: absolute source path}, plus the manifest."""
    mapping = {}
    for relative in swift_sources():
        mapping[relative] = os.path.join(SOURCE, relative)
    for relative in RESOURCE_FILES:
        source = os.path.join(SOURCE, relative)
        if not os.path.exists(source):
            raise SystemExit(f"missing resource: {os.path.relpath(source, ROOT)}")
        mapping[relative] = source
    return mapping


def generate():
    mapping = planned_files()

    if os.path.isdir(TARGET):
        shutil.rmtree(TARGET)
    os.makedirs(TARGET)

    for relative, source in mapping.items():
        destination = os.path.join(TARGET, relative)
        os.makedirs(os.path.dirname(destination), exist_ok=True)
        shutil.copyfile(source, destination)

    with open(os.path.join(TARGET, "Package.swift"), "w", encoding="utf-8") as handle:
        handle.write(PACKAGE_SWIFT)

    print(f"wrote {len(mapping) + 1} files to {os.path.relpath(TARGET, ROOT)}/")
    for relative in sorted(mapping):
        print(f"  {relative}")
    print("  Package.swift")


def check():
    """Fail if the mirror is missing, stale, or has files the sources don't."""
    problems = []

    if not os.path.isdir(TARGET):
        print("FAIL: CrosswordBonanza.swiftpm/ does not exist -- run make_swiftpm.py")
        return 1

    mapping = planned_files()
    expected = set(mapping) | {"Package.swift"}

    actual = set()
    for dirpath, _, filenames in os.walk(TARGET):
        for name in filenames:
            full = os.path.join(dirpath, name)
            actual.add(os.path.relpath(full, TARGET))

    for missing in sorted(expected - actual):
        problems.append(f"missing from the package: {missing}")
    for extra in sorted(actual - expected):
        problems.append(f"stale file in the package: {extra}")

    for relative, source in mapping.items():
        destination = os.path.join(TARGET, relative)
        if not os.path.exists(destination):
            continue
        if not filecmp.cmp(source, destination, shallow=False):
            problems.append(f"out of date, regenerate: {relative}")

    manifest = os.path.join(TARGET, "Package.swift")
    if os.path.exists(manifest):
        with open(manifest, encoding="utf-8") as handle:
            if handle.read() != PACKAGE_SWIFT:
                problems.append("Package.swift does not match the generator")

    # The app has to have exactly one entry point, same as the Xcode target.
    entry_points = []
    for relative in mapping:
        if not relative.endswith(".swift"):
            continue
        with open(os.path.join(SOURCE, relative), encoding="utf-8") as handle:
            if "@main" in handle.read():
                entry_points.append(relative)
    if len(entry_points) != 1:
        problems.append(f"expected exactly one @main, found {entry_points}")

    for problem in problems:
        print("FAIL:", problem)
    print(f"\nswiftpm mirror: {len(expected)} files, {len(problems)} problems")
    return 1 if problems else 0


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--check",
        action="store_true",
        help="verify the mirror is in sync instead of regenerating it",
    )
    args = parser.parse_args()

    if args.check:
        return check()
    generate()
    return 0


if __name__ == "__main__":
    sys.exit(main())
