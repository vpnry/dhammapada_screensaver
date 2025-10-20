#!/usr/bin/env python3
"""Parse a text of chapters (vagga) and stanzas into JSON.

Usage:
    python parse_text_to_json.py input.txt [output.json]

If output.json is omitted, prints to stdout.

Assumptions:
- Chapter lines match: ^\d+\.\s+.*$  (e.g., "2. Appamādavaggo")
- Stanza number lines match: ^\d+\.$  or ^\d+\.\s*$  (e.g., "21.")
- Stanza content follows the stanza number and may span multiple lines until the next stanza number or chapter.
- Square-bracketed editorial variants are treated as raw text and left as-is.
"""

import sys
import json
import re
from pathlib import Path

CHAPTER_RE = re.compile(r"^(\d+)\.\s+(.+)$")
STANZA_RE = re.compile(r"^(\d+)\.$")


def normalize_whitespace(s: str) -> str:
    # collapse multiple spaces and newlines into single spaces, strip
    return re.sub(r"\s+", " ", s).strip()


def parse_text(text: str):
    chapters = {}
    current_chapter = None
    current_stanza_no = None
    current_stanza_lines = []

    lines = text.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if not line:
            i += 1
            continue

        chap_m = CHAPTER_RE.match(line)
        if chap_m:
            # if a stanza was being collected for the previous chapter, flush it
            if (
                current_chapter
                and current_stanza_no is not None
                and current_stanza_lines
            ):
                norm_lines = [
                    normalize_whitespace(l) for l in current_stanza_lines if l.strip()
                ]
                content = "\\n".join(norm_lines)
                chapters.setdefault(current_chapter, {})[current_stanza_no] = content

            chap_num, chap_title = chap_m.groups()
            current_chapter = f"{chap_num}. {chap_title}"
            chapters[current_chapter] = {}
            current_stanza_no = None
            current_stanza_lines = []
            i += 1
            continue

        st_m = STANZA_RE.match(line)
        if st_m:
            # save previous stanza if any
            if current_stanza_no is not None:
                # normalize each line individually (collapse internal spaces) and join with \n
                norm_lines = [
                    normalize_whitespace(l) for l in current_stanza_lines if l.strip()
                ]
                content = "\\n".join(norm_lines)
                chapters[current_chapter][current_stanza_no] = content
            current_stanza_no = st_m.group(1)
            current_stanza_lines = []
            i += 1
            # collect stanza lines until next stanza or chapter or blank
            while i < len(lines):
                nxt = lines[i].strip()
                if not nxt:
                    i += 1
                    continue
                if CHAPTER_RE.match(nxt) or STANZA_RE.match(nxt):
                    break
                current_stanza_lines.append(nxt)
                i += 1
            # loop will continue and save stanza on next stanza or chapter or end
            continue

        # If we reach here, the line is content without an explicit stanza number
        # Attach it to the last stanza if available, else ignore or attach to chapter under special key
        if current_stanza_no is not None:
            current_stanza_lines.append(line)
        else:
            # attach to chapter-level under key "_meta" or accumulate
            if current_chapter is None:
                # stray text before first chapter: skip
                i += 1
                continue
            chapters.setdefault(current_chapter, {}).setdefault("_meta", "")
            prev = chapters[current_chapter]["_meta"]
            chapters[current_chapter]["_meta"] = (prev + " " + line).strip()
        i += 1

    # at EOF, flush last stanza
    if current_chapter and current_stanza_no is not None and current_stanza_lines:
        norm_lines = [
            normalize_whitespace(l) for l in current_stanza_lines if l.strip()
        ]
        content = "\\n".join(norm_lines)
        chapters[current_chapter][current_stanza_no] = content

    return chapters


def main(argv):
    if len(argv) < 2:
        print("Usage: parse_text_to_json.py input.txt [output.json]")
        return 1
    in_path = Path(argv[1])
    if not in_path.exists():
        print(f"Input file {in_path} not found")
        return 2
    text = in_path.read_text(encoding="utf-8")
    parsed = parse_text(text)
    out = json.dumps(parsed, ensure_ascii=False, indent=4)
    if len(argv) >= 3:
        out_path = Path(argv[2])
        out_path.write_text(out, encoding="utf-8")
        print(f"Written JSON to {out_path}")
    else:
        print(out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
