#!/usr/bin/env python3
"""
regression.py
-------------
Parses sim_log.txt produced by ModelSim, prints a clean pass/fail
table, writes report.html and exits 0 on all-pass, 1 on any fail.

Usage:
    python regression.py                # reads ./sim_log.txt
    python regression.py some_log.txt   # reads a custom log

Dependencies:
    - Only Python standard library is required.
    - 'tabulate' is used automatically if installed; otherwise a
       pure-stdlib formatter is used.
"""

import os
import re
import sys
from datetime import datetime

LOG_FILE  = sys.argv[1] if len(sys.argv) > 1 else "sim_log.txt"
HTML_FILE = "report.html"

# --------- Optional tabulate import with graceful fallback ---------
try:
    from tabulate import tabulate
    _HAS_TABULATE = True
except ImportError:
    _HAS_TABULATE = False


def print_results_table(results):
    """Print the pass/fail table. Uses tabulate when available."""
    headers = ["#", "Status", "Test", "Detail"]
    rows = [
        [i + 1, r["status"], r["test"], r.get("detail", "")]
        for i, r in enumerate(results)
    ]

    if _HAS_TABULATE:
        print(tabulate(rows, headers=headers, tablefmt="fancy_grid"))
        return

    # --- Pure-stdlib fallback formatter ---
    col_w = [4, 8, 42, 42]
    sep = "+".join("-" * (w + 2) for w in col_w)
    sep = "+" + sep + "+"

    def fmt_row(cells):
        return "| " + " | ".join(
            str(c).ljust(col_w[i])[: col_w[i]] for i, c in enumerate(cells)
        ) + " |"

    print(sep)
    print(fmt_row(headers))
    print(sep)
    for r in rows:
        print(fmt_row(r))
    print(sep)


def parse_log(path):
    """Extract PASS/FAIL result rows from the log file."""
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        lines = f.readlines()

    # ModelSim usually prefixes $display lines with '# '
    fail_re = re.compile(
        r"^\s*(?:#\s*)?FAIL\s+(\S+)\s+expected=(\S+)\s+actual=(\S+)"
    )
    pass_re = re.compile(r"^\s*(?:#\s*)?PASS\s+(\S+)")

    results = []
    for line in lines:
        m = fail_re.match(line)
        if m:
            results.append({
                "status": "FAIL",
                "test":   m.group(1),
                "detail": f"expected={m.group(2)} actual={m.group(3)}",
            })
            continue
        m = pass_re.match(line)
        if m:
            results.append({
                "status": "PASS",
                "test":   m.group(1),
                "detail": "",
            })
    return results


def write_html_report(results, passed, failed, total):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    pass_pct  = (100.0 * passed / total) if total else 0.0
    overall   = "ALL TESTS PASSED" if (failed == 0 and total > 0) else "FAILURES DETECTED"
    bar_color = "#28a745" if (failed == 0 and total > 0) else "#dc3545"

    row_html = []
    for i, r in enumerate(results):
        bg  = "#d4edda" if r["status"] == "PASS" else "#f8d7da"
        fg  = "#155724" if r["status"] == "PASS" else "#721c24"
        row_html.append(
            f'<tr style="background:{bg}">'
            f'<td>{i + 1}</td>'
            f'<td style="color:{fg};font-weight:bold">{r["status"]}</td>'
            f'<td><code>{r["test"]}</code></td>'
            f'<td>{r.get("detail", "")}</td>'
            f'</tr>'
        )

    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Memory Controller Regression Report</title>
<style>
  body   {{ font-family: system-ui, Segoe UI, sans-serif;
           background:#f4f6f9; padding:24px; color:#222; }}
  h1     {{ margin:0 0 4px 0; }}
  .meta  {{ color:#666; font-size:13px; margin-bottom:20px; }}
  .bar   {{ padding:14px 18px; border-radius:8px; color:white;
           background:{bar_color}; font-weight:700; font-size:18px;
           margin-bottom:20px; }}
  table  {{ border-collapse:collapse; width:100%;
           background:white; box-shadow:0 2px 10px rgba(0,0,0,.08); }}
  th, td {{ padding:10px 14px; text-align:left;
           border-bottom:1px solid #e5e7eb; }}
  th     {{ background:#343a40; color:white; }}
  code   {{ font-family: ui-monospace, Consolas, monospace; }}
</style>
</head>
<body>
  <h1>Memory Controller — Regression Report</h1>
  <div class="meta">Generated {timestamp} &nbsp;|&nbsp; log: <code>{LOG_FILE}</code></div>
  <div class="bar">{overall} &nbsp;|&nbsp; {passed}/{total} tests passed ({pass_pct:.1f}%)</div>
  <table>
    <tr><th>#</th><th>Status</th><th>Test</th><th>Detail</th></tr>
    {''.join(row_html)}
  </table>
</body>
</html>
"""
    with open(HTML_FILE, "w", encoding="utf-8") as f:
        f.write(html)


def main():
    if not os.path.exists(LOG_FILE):
        print(f"ERROR: log file '{LOG_FILE}' not found. "
              f"Did you run the simulation first?")
        sys.exit(2)

    results = parse_log(LOG_FILE)
    passed  = sum(1 for r in results if r["status"] == "PASS")
    failed  = sum(1 for r in results if r["status"] == "FAIL")
    total   = len(results)

    print("=" * 70)
    print("  MEMORY CONTROLLER - REGRESSION REPORT")
    print("=" * 70)

    if total == 0:
        print(f"No PASS/FAIL tags found in '{LOG_FILE}'.")
        print("Make sure the simulation ran successfully.")
        sys.exit(1)

    print_results_table(results)

    print()
    print(f"  PASSED : {passed}")
    print(f"  FAILED : {failed}")
    print(f"  TOTAL  : {total}")
    print(f"  PASS%  : {100.0 * passed / total:.1f}%")
    print("=" * 70)

    write_html_report(results, passed, failed, total)
    print(f"HTML report written to: {HTML_FILE}")

    sys.exit(0 if failed == 0 else 1)


if __name__ == "__main__":
    main()