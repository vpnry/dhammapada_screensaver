#!/usr/bin/env python3
"""Reads `dhammapada.json` and writes an Objective-C `VerseDatabase..m`

Usage:
    python3 parse_json_to_dictm.py [in_json] [out_file]

Defaults:
    in_json: dhammapada.json
    out_file: VerseDatabase.m
"""

import json
import sys
from pathlib import Path
import re

# Defaults
DEFAULT_IN = Path("dhammapada.json")
# Default output: write directly into the Xcode target folder as VerseDatabase.m if no [out_file] given
DEFAULT_OUT = Path("../Xcode/DhammapadaScreenSaver/VerseDatabase.m")

in_path = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_IN
out_path = Path(sys.argv[2]) if len(sys.argv) > 2 else DEFAULT_OUT

if not in_path.exists():
    print(f"Input JSON not found: {in_path}")
    sys.exit(1)

with in_path.open("r", encoding="utf-8") as f:
    data = json.load(f)


def objc_escape(s: str) -> str:
    """Escape a Python string for inclusion as an Objective-C @"..." literal.

    - backslashes become \\
    - double quotes become \"
    - newlines become \n (two characters)
    """
    if s is None:
        return ""
    s = s.replace("\\", "\\\\")
    s = s.replace('"', '\\"')
    s = s.replace("\n", "\\n")
    return s


entries = []
for chapter_name, verses in data.items():
    # chapter_name like "1. Yamakavaggo"
    if not isinstance(verses, dict):
        continue
    # Normalize chapter names like "1. Yamakavaggo" -> "1: Yamakavaggo"
    def format_chapter_name(name: str) -> str:
        if name is None:
            return ""
        # Replace an initial number followed by a dot with a colon (only the first occurrence)
        # e.g. "1. Yamakavaggo" -> "1: Yamakavaggo"
        return re.sub(r'^\s*(\d+)\.\s*', r'\1: ', str(name).strip())
    for verse_num, pali_text in verses.items():
        # Skip non-numeric verse keys (like the closing line markers sometimes present)
        if not str(verse_num).strip().isdigit():
            continue
        entry = {
            "chapter": f"Chapter {format_chapter_name(chapter_name)}",
            "verse": f"Verse {verse_num}",
            "pali": pali_text if pali_text is not None else "",
            "entrans": pali_text if pali_text is not None else "",
            "vitrans": pali_text if pali_text is not None else "",
        }
        entries.append(entry)


# We'll produce only the Objective-C array literal (starting with @[
# and then embed that literal into the VerseDatabase.m template below.
array_header = "@[\n"

body_lines = [array_header]
for e in entries:
    pali = objc_escape(e["pali"])
    entrans = objc_escape(e["entrans"])
    vitrans = objc_escape(e["vitrans"])

    # If the original text already contained literal "\\n" sequences (two chars),
    # objc_escape will have escaped the backslash to "\\\\n". Convert those
    # double-escaped newlines back to a single "\\n" so the Objective-C literal
    # contains the intended newline escape sequence.
    pali = pali.replace("\\\\n", "\\n")
    entrans = entrans.replace("\\\\n", "\\n")
    vitrans = vitrans.replace("\\\\n", "\\n")

    verse = objc_escape(e["verse"])
    chapter = objc_escape(e["chapter"])
    # Emit keys in requested order: chapter, verse, pali, entrans, vitrans
    # Use Objective-C literal style with @"key": @"value"
    block = (
        f'      @{{@"chapter": @"{chapter}",\n'
        f'        @"verse": @"{verse}",\n'
        f'        @"pali": @"{pali}",\n'
        f'        @"entrans": @"{entrans}",\n'
        f'        @"vitrans": @"{vitrans}"}},\n'
    )
    body_lines.append(block)

array_footer = "];\n"
body_lines.append(array_footer)

# Combine into the VerseDatabase.m template
template_header = (
    "//\n"
    "//  VerseDatabase.m\n"
    "//  DhammapadaScreenSaver\n"
    "//\n"
    "//  Dhammapada verses are adapted from https://tipitakapali.org/book/s0502m.mul.html\n"
    "//\n\n"
    '#import "VerseDatabase.h"\n\n'
    "NSArray *kDhammapadaVerseDatabase = nil;\n\n"
    "__attribute__((constructor)) static void initializeVerseDatabase(void) {\n"
    "    // Small static initializer to populate the global database when the bundle is loaded.\n"
    "    kDhammapadaVerseDatabase = "
)

template_footer = "\n}\n"

out_text = template_header + "".join(body_lines) + template_footer

out_path.parent.mkdir(parents=True, exist_ok=True)
out_path.write_text(out_text, encoding="utf-8")
print(f"Wrote {out_path} with {len(entries)} entries")
