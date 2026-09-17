#!/usr/bin/env python3
"""Structural sanity check for the hand-written Xcode project.

`project.pbxproj` was authored without a Mac to open it on, so this script
catches the errors that are actually likely from hand-authoring: unbalanced
braces, an object id referenced but never defined, a dangling build phase, a
missing rootObject. It cannot tell you the project *builds* -- only Xcode can --
but a clean run here rules out the whole class of typo-shaped failures.

It also checks the asset catalog JSON and the scheme XML parse.

Usage:  python3 Tools/check_project.py
"""

import json
import os
import re
import sys
import xml.etree.ElementTree as ElementTree

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PBXPROJ = os.path.join(ROOT, "CrosswordBonanza.xcodeproj", "project.pbxproj")
SCHEME = os.path.join(
    ROOT, "CrosswordBonanza.xcodeproj", "xcshareddata", "xcschemes",
    "CrosswordBonanza.xcscheme",
)
ASSETS = os.path.join(ROOT, "CrosswordBonanza", "Resources", "Assets.xcassets")

ID_PATTERN = re.compile(r"\b[0-9A-F]{24}\b")
DEFINITION_PATTERN = re.compile(r"^\s*([0-9A-F]{24})\b.*?=\s*\{", re.M)

REQUIRED_ISA = [
    "PBXFileReference",
    "PBXFileSystemSynchronizedRootGroup",
    "PBXFrameworksBuildPhase",
    "PBXGroup",
    "PBXNativeTarget",
    "PBXProject",
    "PBXResourcesBuildPhase",
    "PBXSourcesBuildPhase",
    "XCBuildConfiguration",
    "XCConfigurationList",
]


def check_pbxproj(problems):
    if not os.path.exists(PBXPROJ):
        problems.append("project.pbxproj is missing")
        return

    with open(PBXPROJ, encoding="utf-8") as handle:
        text = handle.read()

    if not text.startswith("// !$*UTF8*$!"):
        problems.append("project.pbxproj is missing its encoding header")

    # Strip comments so braces inside them cannot confuse the balance check.
    stripped = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    stripped = re.sub(r"//.*", "", stripped)

    for open_char, close_char in (("{", "}"), ("(", ")")):
        opened = stripped.count(open_char)
        closed = stripped.count(close_char)
        if opened != closed:
            problems.append(
                f"project.pbxproj has {opened} '{open_char}' but {closed} '{close_char}'"
            )

    defined = set(DEFINITION_PATTERN.findall(text))
    referenced = set(ID_PATTERN.findall(text)) - defined

    # Every id mentioned anywhere must correspond to a defined object.
    all_mentioned = set(ID_PATTERN.findall(text))
    dangling = sorted(all_mentioned - defined)
    if dangling:
        problems.append(f"project.pbxproj references undefined object ids: {dangling}")

    # Every defined object except the root must be reachable from somewhere.
    root_match = re.search(r"rootObject\s*=\s*([0-9A-F]{24})", text)
    if not root_match:
        problems.append("project.pbxproj has no rootObject")
        root_id = None
    else:
        root_id = root_match.group(1)
        if root_id not in defined:
            problems.append(f"rootObject {root_id} is not defined")

    for object_id in sorted(defined):
        if object_id == root_id:
            continue
        # Count mentions outside its own definition line.
        mentions = len(re.findall(rf"\b{object_id}\b", text))
        if mentions < 2:
            problems.append(f"object {object_id} is defined but never referenced")

    for isa in REQUIRED_ISA:
        if f"isa = {isa};" not in text:
            problems.append(f"project.pbxproj has no {isa} object")

    # The synchronized group is what makes source files appear in the target
    # without being listed one by one, so the link between them must exist.
    if "fileSystemSynchronizedGroups" not in text:
        problems.append("the app target does not reference a file-system synchronized group")

    sync_match = re.search(
        r"isa = PBXFileSystemSynchronizedRootGroup;\s*path = ([^;]+);", text
    )
    if sync_match:
        folder = sync_match.group(1).strip().strip('"')
        if not os.path.isdir(os.path.join(ROOT, folder)):
            problems.append(f"synchronized group points at {folder}/ which does not exist")
    else:
        problems.append("could not read the synchronized group's path")

    if "objectVersion = 77;" not in text:
        problems.append("objectVersion is not 77 (synchronized groups need Xcode 16)")

    # Everything the Swift code assumes about the build settings.
    for setting in (
        "SWIFT_VERSION = 5.0;",
        "IPHONEOS_DEPLOYMENT_TARGET = 17.0;",
        "GENERATE_INFOPLIST_FILE = YES;",
        "TARGETED_DEVICE_FAMILY = \"1,2\";",
    ):
        if setting not in text:
            problems.append(f"build setting missing: {setting}")


def check_scheme(problems):
    if not os.path.exists(SCHEME):
        problems.append("the shared scheme is missing")
        return
    try:
        tree = ElementTree.parse(SCHEME)
    except ElementTree.ParseError as error:
        problems.append(f"the scheme is not valid XML: {error}")
        return

    blueprints = {
        element.get("BlueprintIdentifier")
        for element in tree.iter("BuildableReference")
    }
    with open(PBXPROJ, encoding="utf-8") as handle:
        pbxproj = handle.read()
    for blueprint in blueprints:
        if blueprint and blueprint not in pbxproj:
            problems.append(f"the scheme points at unknown target id {blueprint}")


def check_assets(problems):
    if not os.path.isdir(ASSETS):
        problems.append("Assets.xcassets is missing")
        return
    expected = [
        os.path.join(ASSETS, "Contents.json"),
        os.path.join(ASSETS, "AppIcon.appiconset", "Contents.json"),
        os.path.join(ASSETS, "AccentColor.colorset", "Contents.json"),
    ]
    for path in expected:
        if not os.path.exists(path):
            problems.append(f"missing asset catalog file: {os.path.relpath(path, ROOT)}")
            continue
        try:
            with open(path, encoding="utf-8") as handle:
                json.load(handle)
        except json.JSONDecodeError as error:
            problems.append(f"{os.path.relpath(path, ROOT)} is not valid JSON: {error}")


def is_inside(path, directory):
    """True if `path` is `directory` or sits under it.

    Deliberately not `startswith`: that would treat CrosswordBonanza.swiftpm/ as
    being inside CrosswordBonanza/, because one string is a prefix of the other.
    """
    return os.path.commonpath([os.path.abspath(path), os.path.abspath(directory)]) == \
        os.path.abspath(directory)


def check_sources(problems):
    """Every Swift file must sit inside the synchronized folder, or the Xcode
    target will silently not compile it.

    The one sanctioned exception is the generated Swift Playgrounds mirror, whose
    contents are checked by Tools/make_swiftpm.py --check instead.
    """
    app_root = os.path.join(ROOT, "CrosswordBonanza")
    swiftpm_root = os.path.join(ROOT, "CrosswordBonanza.swiftpm")

    stray = []
    for dirpath, dirnames, filenames in os.walk(ROOT):
        dirnames[:] = [d for d in dirnames if d not in {".git", ".build", "DerivedData"}]
        if is_inside(dirpath, app_root) or is_inside(dirpath, swiftpm_root):
            continue
        for name in filenames:
            if name.endswith(".swift"):
                stray.append(os.path.relpath(os.path.join(dirpath, name), ROOT))
    for path in stray:
        problems.append(f"{path} is outside CrosswordBonanza/ so it will not be compiled")

    if os.path.isdir(swiftpm_root):
        manifest = os.path.join(swiftpm_root, "Package.swift")
        if not os.path.exists(manifest):
            problems.append("CrosswordBonanza.swiftpm/ has no Package.swift")
        else:
            with open(manifest, encoding="utf-8") as handle:
                text = handle.read()
            for needed in ("import AppleProductTypes", ".iOSApplication("):
                if needed not in text:
                    problems.append(f"Package.swift is missing {needed}")
            for open_char, close_char in (("(", ")"), ("[", "]")):
                if text.count(open_char) != text.count(close_char):
                    problems.append(f"Package.swift has unbalanced {open_char}{close_char}")

    # Exactly one @main, counted in the source of truth only -- the mirror
    # carries a copy of it and would otherwise double the count.
    entry_points = []
    for dirpath, _, filenames in os.walk(app_root):
        for name in filenames:
            if not name.endswith(".swift"):
                continue
            with open(os.path.join(dirpath, name), encoding="utf-8") as handle:
                if "@main" in handle.read():
                    entry_points.append(name)
    if len(entry_points) != 1:
        problems.append(f"expected exactly one @main entry point, found {entry_points}")


def main():
    problems = []
    check_pbxproj(problems)
    check_scheme(problems)
    check_assets(problems)
    check_sources(problems)

    for problem in problems:
        print("FAIL:", problem)
    print(f"\nproject structure: {len(problems)} problems")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
