#!/usr/bin/env python3
"""
Extract every HTTP/HTTPS URL in a text source and save them to links.txt.
Duplicates are removed and the list is sorted for convenience.
"""

import re
import sys
from pathlib import Path

# --- configuration ----------------------------------------------------------
INPUT_FILE = "index.html"        # put your source text file here
OUTPUT_FILE = "links.txt"
URL_RX = re.compile(
    r"""(?xi)                     # verbose / case-insensitive
    \b                            # word boundary
    (?:https?://|www\.)           # scheme or bare www.
    [^\s<>"'()\[\]]+              # anything except whitespace or common terminators
    """
)
# ---------------------------------------------------------------------------

# 1. Read the text (fallback to stdin if the file isn’t present)
if Path(INPUT_FILE).is_file():
    text = Path(INPUT_FILE).read_text(encoding="utf-8", errors="ignore")
else:
    text = sys.stdin.read()

# 2. Extract, deduplicate, and sort
urls = sorted(set(URL_RX.findall(text)))

# 3. Write to the output file
Path(OUTPUT_FILE).write_text("\n".join(urls), encoding="utf-8")

print(f"✅  Saved {len(urls)} link(s) to {OUTPUT_FILE}")

