#!/usr/bin/env python3
"""Export disposable client credentials and Helm overrides without printing secrets."""
import json
import os
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parent
result = subprocess.run(["terraform", f"-chdir={root}", "output", "-json"],
                        check=True, capture_output=True, text=True)
outputs = json.loads(result.stdout)
out = root / "generated"
out.mkdir(exist_ok=True, mode=0o700)
os.chmod(out, 0o700)
for name, content in outputs["client_files"]["value"].items():
    target = out / name
    fd = os.open(target, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as f:
        f.write(content)
    os.chmod(target, 0o600)
(out / "mtls-values.json").write_text(json.dumps(outputs["helm_values"]["value"], indent=2) + "\n")
print("Exported test certificates and generated/mtls-values.json")
