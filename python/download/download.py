#!/usr/bin/env python3
# /// script
# requires-python = ">=3.13"
# dependencies = [
#     "requests",
#     "tqdm",
# ]
# ///
import os
import sys
import requests
from pathlib import Path
from tqdm import tqdm


with open("links2.txt") as f:
  for l in f:
    fpath = l.strip("\n\r ").split("?")[0]
    print(f"[{fpath}]\t", end="")
    local = Path(Path(fpath).name)
    pos   = os.path.getsize(local) if os.path.exists(local) else 0
    headers = {"Range": f"bytes={pos}-"} if pos else {}
    if local.exists():
      if local.stat().st_size > 0:
        print("DONE (exists).")
        continue
    print("downloading:")
    with requests.get(fpath, stream=True, headers=headers, timeout=20) as r:
      r.raise_for_status()
      total = int(r.headers.get("Content-Range","").split("/")[-1] or r.headers.get("Content-Length",0))
      with open(local, "ab") as f, tqdm(
          total=total, initial=pos, unit="B",  desc=f"{local}" 
        ) as bar:
          for chunk in r.iter_content(chunk_size=1024*1024):
             if chunk:
                f.write(chunk)
                bar.update(len(chunk))
