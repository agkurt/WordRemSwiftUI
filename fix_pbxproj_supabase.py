#!/usr/bin/env python3
"""
fix_pbxproj_supabase.py  (v2)
------------------------------
1. Removes the wrong PBXFileReference/PBXBuildFile entries added by v1
   (those used bare filenames causing Xcode to look in the project root).
2. Adds correct entries with paths relative to SOURCE_ROOT.

Run from the repo root:
    python3 fix_pbxproj_supabase.py
"""

import re, uuid, os

PBXPROJ = "WordRemSwiftUI.xcodeproj/project.pbxproj"

# path relative to SOURCE_ROOT (= repo root / WordRemSwiftUI.xcodeproj parent)
NEW_FILES = [
    ("WordRemSwiftUI/Services/SupabaseService/SupabaseService.swift",    "SupabaseService.swift"),
    ("WordRemSwiftUI/Services/SupabaseService/SupabaseModels.swift",     "SupabaseModels.swift"),
    ("WordRemSwiftUI/Services/SupabaseService/SupabaseAuthService.swift","SupabaseAuthService.swift"),
    ("WordRemSwiftUI/Services/SupabaseService/SupabaseDataService.swift","SupabaseDataService.swift"),
    ("WordRemSwiftUI/ViewModel/Path/PathMapViewModel.swift",             "PathMapViewModel.swift"),
    ("WordRemSwiftUI/ViewModel/Quiz/GameQuizViewModel.swift",            "GameQuizViewModel.swift"),
    ("WordRemSwiftUI/ViewModel/Leaderboard/LeaderboardViewModel.swift",  "LeaderboardViewModel.swift"),
    ("WordRemSwiftUI/View/Path/PathMapView.swift",                       "PathMapView.swift"),
    ("WordRemSwiftUI/View/Quiz/GameQuizView.swift",                      "GameQuizView.swift"),
    ("WordRemSwiftUI/View/Quiz/QuizResultView.swift",                    "QuizResultView.swift"),
    ("WordRemSwiftUI/View/Leaderboard/LeaderboardView.swift",            "LeaderboardView.swift"),
    ("WordRemSwiftUI/View/ProfileView/ProfileView.swift",                "ProfileView.swift"),
]

ALL_NAMES = [n for _, n in NEW_FILES]

def make_id():
    return uuid.uuid4().hex[:24].upper()

def main():
    with open(PBXPROJ, "r", encoding="utf-8") as f:
        content = f.read()

    # ── STEP 1: Remove all previously added (wrong) entries ──────────────────
    lines = content.splitlines(keepends=True)
    cleaned = []
    for line in lines:
        should_remove = any(name in line for name in ALL_NAMES)
        if should_remove:
            print(f"  REMOVING: {line.rstrip()}")
        else:
            cleaned.append(line)
    content = "".join(cleaned)

    # ── STEP 2: Verify source files actually exist ────────────────────────────
    missing = [p for p, _ in NEW_FILES if not os.path.isfile(p)]
    if missing:
        print("⚠️  Some source files not found (check paths):")
        for m in missing:
            print(f"   {m}")
    else:
        print("✅ All source files found on disk.")

    # ── STEP 3: Generate IDs and build blocks ─────────────────────────────────
    entries = []
    for src_path, name in NEW_FILES:
        entries.append({
            "src_path":     src_path,
            "name":         name,
            "file_ref_id":  make_id(),
            "build_file_id": make_id(),
        })

    # ── STEP 4: PBXBuildFile ──────────────────────────────────────────────────
    build_file_block = ""
    for e in entries:
        build_file_block += (
            f'\t\t{e["build_file_id"]} /* {e["name"]} in Sources */ = '
            f'{{isa = PBXBuildFile; fileRef = {e["file_ref_id"]} /* {e["name"]} */; }};\n'
        )
    content = content.replace(
        "/* End PBXBuildFile section */",
        build_file_block + "/* End PBXBuildFile section */"
    )

    # ── STEP 5: PBXFileReference (with sourceTree = SOURCE_ROOT, full path) ───
    file_ref_block = ""
    for e in entries:
        file_ref_block += (
            f'\t\t{e["file_ref_id"]} /* {e["name"]} */ = '
            f'{{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; '
            f'name = "{e["name"]}"; path = "{e["src_path"]}"; sourceTree = SOURCE_ROOT; }};\n'
        )
    content = content.replace(
        "/* End PBXFileReference section */",
        file_ref_block + "/* End PBXFileReference section */"
    )

    # ── STEP 6: Insert build file IDs into PBXSourcesBuildPhase ──────────────
    # Match the first (and usually only) PBXSourcesBuildPhase files list
    pattern = re.compile(
        r'(isa = PBXSourcesBuildPhase;.*?files\s*=\s*\()(.*?)(\s*\);)',
        re.DOTALL
    )
    match = pattern.search(content)
    if match:
        new_refs = ""
        for e in entries:
            new_refs += f'\n\t\t\t\t{e["build_file_id"]} /* {e["name"]} in Sources */,'
        updated_files = match.group(2).rstrip() + new_refs + "\n\t\t\t"
        content = content[:match.start(2)] + updated_files + content[match.end(2):]
        print(f"✅ Inserted {len(entries)} build file references into PBXSourcesBuildPhase.")
    else:
        print("⚠️  PBXSourcesBuildPhase not found — add files manually in Xcode.")

    # ── STEP 7: Write back ────────────────────────────────────────────────────
    with open(PBXPROJ, "w", encoding="utf-8") as f:
        f.write(content)
    print("✅ project.pbxproj saved — re-open Xcode and build.")

if __name__ == "__main__":
    main()
