#!/usr/bin/env python3
"""
tools/regression.py
-------------------
Parse a simulation log (simple or UVM) and emit:
  * Console summary table
  * Exit 0 on all-pass / 1 on any failure / 2 if log missing

Usage:
    python tools/regression.py reports/simple_sim_log.txt
    python tools/regression.py reports/uvm_sim_log.txt
    python tools/regression.py reports/uvm_bug_log.txt
"""

from __future__ import annotations
import os
import re
import sys
import tabulate

try:
    from tabulate import tabulate
    _HAS_TAB = True
except ImportError:
    _HAS_TAB = False

PASS_RE       = re.compile(r"\bPASS\s+(\S+)")
FAIL_RE       = re.compile(r"\bFAIL\s+(\S+)(?:\s+expected=(\S+)\s+actual=(\S+))?")
UVM_ERROR_RE  = re.compile(r"^\s*(?:#\s*)?UVM_ERROR\b")
UVM_FATAL_RE  = re.compile(r"^\s*(?:#\s*)?UVM_FATAL\b")
UVM_RPT_RE    = re.compile(r"UVM_(ERROR|FATAL|WARNING|INFO)\s*:\s*(\d+)", re.I)


def parse_log(path: str):
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        lines = f.readlines()

    rows: list[dict] = []
    uvm_err = uvm_fatal = 0

    for ln in lines:
        # Skip the UVM final summary lines (counts) — handled separately
        m = FAIL_RE.search(ln)
        if m:
            detail = ""
            if m.group(2) and m.group(3):
                detail = f"expected={m.group(2)} actual={m.group(3)}"
            rows.append({"status": "FAIL", "test": m.group(1), "detail": detail})
            continue
        m = PASS_RE.search(ln)
        if m:
            rows.append({"status": "PASS", "test": m.group(1), "detail": ""})
            continue

        if UVM_ERROR_RE.search(ln):
            uvm_err += 1
        elif UVM_FATAL_RE.search(ln):
            uvm_fatal += 1

    return rows, uvm_err, uvm_fatal


def render(rows):
    if not rows:
        print("(no PASS/FAIL lines found)")
        return
    headers = ["#", "Status", "Test", "Detail"]
    table = [[i + 1, r["status"], r["test"], r["detail"]] for i, r in enumerate(rows)]
    if _HAS_TAB:
        print(tabulate(table, headers=headers, tablefmt="fancy_grid"))
        return
    w = [4, 8, 44, 40]
    sep = "+" + "+".join("-" * (x + 2) for x in w) + "+"
    fmt = lambda c: "| " + " | ".join(str(c[i]).ljust(w[i])[:w[i]] for i in range(4)) + " |"
    print(sep); print(fmt(headers)); print(sep)
    for r in table: print(fmt(r))
    print(sep)


def main():
    if len(sys.argv) < 2:
        print("Usage: python tools/regression.py <path/to/sim_log.txt>")
        sys.exit(2)
    path = sys.argv[1]
    if not os.path.isfile(path):
        print(f"ERROR: log file not found: {path}")
        sys.exit(2)

    rows, uvm_err, uvm_fatal = parse_log(path)

    print("=" * 72)
    print(f"  REGRESSION REPORT  [{path}]")
    print("=" * 72)
    render(rows)

    passed = sum(1 for r in rows if r["status"] == "PASS")
    failed = sum(1 for r in rows if r["status"] == "FAIL")
    total  = passed + failed

    print()
    print(f"  PASS         : {passed}")
    print(f"  FAIL         : {failed}")
    print(f"  TOTAL CHECKS : {total}")
    print(f"  UVM_ERROR    : {uvm_err}")
    print(f"  UVM_FATAL    : {uvm_fatal}")
    if total:
        print(f"  PASS%        : {100.0 * passed / total:.1f}%")
    print("=" * 72)

    bad = failed > 0 or uvm_err > 0 or uvm_fatal > 0
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()