"""Thin launcher: finds bash, execs the bundled agentscar script. Stdlib only."""
import os
import shutil
import subprocess
import sys

_SCRIPT = os.path.join(os.path.dirname(__file__), "agentscar.sh")


def _find_bash():
    if os.name == "nt":
        pf = os.environ.get("ProgramFiles", r"C:\Program Files")
        for cand in (
            os.path.join(pf, "Git", "bin", "bash.exe"),
            os.path.join(pf, "Git", "usr", "bin", "bash.exe"),
        ):
            if os.path.isfile(cand):
                return cand
    bash = shutil.which("bash")
    # WSL's System32 bash.exe cannot run a Windows-path script — skip it.
    if bash and "system32" not in bash.lower():
        return bash
    return None


def main():
    bash = _find_bash()
    if bash is None:
        sys.stderr.write(
            "agentscar: bash not found. agentscar is a bash script (bash 3.2+).\n"
            "  Windows: install Git for Windows (https://gitforwindows.org), then re-run.\n"
            "  macOS/Linux: install bash via your package manager.\n"
        )
        sys.exit(1)
    sys.exit(subprocess.call([bash, _SCRIPT] + sys.argv[1:]))
