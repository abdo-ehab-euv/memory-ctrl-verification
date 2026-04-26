#!/usr/bin/env python3
"""
tools/dashboard.py
------------------
Read one or more simulation logs and write reports/dashboard.html.

Usage:
    python tools/dashboard.py reports/uvm_sim_log.txt
    python tools/dashboard.py reports/uvm_sim_log.txt reports/uvm_bug_log.txt

The script never crashes on a missing log — it just notes it as N/A.
Pure stdlib; no external dependencies required.
"""

from __future__ import annotations
import html
import os
import re
import sys
from datetime import datetime

OUT_FILE = os.path.join("reports", "dashboard.html")

PASS_RE = re.compile(r"\bPASS\s+(\S+)")
FAIL_RE = re.compile(r"\bFAIL\s+(\S+)(?:\s+expected=(\S+)\s+actual=(\S+))?")
UVM_ERROR_RE = re.compile(r"^\s*(?:#\s*)?UVM_ERROR\b")
UVM_FATAL_RE = re.compile(r"^\s*(?:#\s*)?UVM_FATAL\b")
COV_RE = re.compile(
    r"COVERAGE_REPORT\s+addr=([\d.]+)%\s+op=([\d.]+)%\s+data=([\d.]+)%"
    r"\s+cross=([\d.]+)%\s+trans=([\d.]+)%\s+overall=([\d.]+)%"
)


def analyse(path: str) -> dict:
    if not os.path.isfile(path):
        return {"path": path, "found": False}

    passed, failed, fails, uvm_err, uvm_fatal = 0, 0, [], 0, 0
    cov = None

    with open(path, "r", encoding="utf-8", errors="replace") as f:
        for ln in f:
            if FAIL_RE.search(ln):
                m = FAIL_RE.search(ln)
                failed += 1
                fails.append({
                    "test":   m.group(1),
                    "detail": (f"expected={m.group(2)} actual={m.group(3)}"
                               if m.group(2) and m.group(3) else ""),
                })
            elif PASS_RE.search(ln):
                passed += 1
            if UVM_ERROR_RE.search(ln): uvm_err   += 1
            if UVM_FATAL_RE.search(ln): uvm_fatal += 1
            mc = COV_RE.search(ln)
            if mc:
                cov = {
                    "addr":    float(mc.group(1)),
                    "op":      float(mc.group(2)),
                    "data":    float(mc.group(3)),
                    "cross":   float(mc.group(4)),
                    "trans":   float(mc.group(5)),
                    "overall": float(mc.group(6)),
                }

    total = passed + failed
    return {
        "path": path, "found": True,
        "passed": passed, "failed": failed, "total": total,
        "rate": (100.0 * passed / total) if total else 0.0,
        "uvm_err": uvm_err, "uvm_fatal": uvm_fatal,
        "fails": fails, "coverage": cov,
    }


def render_log_card(r: dict) -> str:
    name = html.escape(os.path.basename(r["path"]))
    if not r["found"]:
        return f"""
        <div class="card">
          <h2>{name}</h2>
          <p class="muted">Log file not found at <code>{html.escape(r['path'])}</code> — run the corresponding TCL script first.</p>
        </div>"""

    overall_ok = r["failed"] == 0 and r["uvm_err"] == 0 and r["uvm_fatal"] == 0 and r["total"] > 0
    badge      = "PASS" if overall_ok else ("EMPTY" if r["total"] == 0 else "FAIL")
    badge_cls  = "ok" if overall_ok else ("muted" if r["total"] == 0 else "bad")

    cov_html = ""
    if r["coverage"]:
        cov_html = "<h3>Functional coverage</h3><div class='cov-grid'>"
        for k, label in [("addr","addresses"),("op","operations"),("data","data classes"),
                         ("cross","addr×op cross"),("trans","addr transitions"),
                         ("overall","OVERALL")]:
            v = r["coverage"][k]
            cov_html += (
                f"<div class='cov-item'><div class='cov-label'>{label}</div>"
                f"<div class='cov-bar'><div class='cov-fill' style='width:{v}%'></div></div>"
                f"<div class='cov-val'>{v:.1f}%</div></div>"
            )
        cov_html += "</div>"
    else:
        cov_html = "<h3>Functional coverage</h3><p class='muted'>No COVERAGE_REPORT line in log.</p>"

    fails_html = ""
    if r["fails"]:
        fails_html = "<h3>Failing checks</h3><table><tr><th>#</th><th>Test</th><th>Detail</th></tr>"
        for i, f in enumerate(r["fails"], 1):
            fails_html += (
                f"<tr><td>{i}</td><td><code>{html.escape(f['test'])}</code></td>"
                f"<td>{html.escape(f['detail'])}</td></tr>"
            )
        fails_html += "</table>"
    elif r["total"]:
        fails_html = "<p class='ok'>No failing checks.</p>"

    return f"""
    <div class="card">
      <h2>{name} <span class="badge {badge_cls}">{badge}</span></h2>
      <div class="kpis">
        <div class="kpi"><div class="num">{r['total']}</div><div>checks</div></div>
        <div class="kpi ok"><div class="num">{r['passed']}</div><div>passed</div></div>
        <div class="kpi bad"><div class="num">{r['failed']}</div><div>failed</div></div>
        <div class="kpi"><div class="num">{r['rate']:.1f}%</div><div>pass rate</div></div>
        <div class="kpi"><div class="num">{r['uvm_err']}</div><div>UVM_ERROR</div></div>
        <div class="kpi"><div class="num">{r['uvm_fatal']}</div><div>UVM_FATAL</div></div>
      </div>
      {cov_html}
      {fails_html}
    </div>"""


def main():
    paths = sys.argv[1:] or ["reports/uvm_sim_log.txt"]
    os.makedirs("reports", exist_ok=True)

    results = [analyse(p) for p in paths]
    cards = "\n".join(render_log_card(r) for r in results)
    ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    page = f"""<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8">
<title>Memory Controller Verification Dashboard</title>
<style>
  body  {{ font-family:system-ui,Segoe UI,sans-serif; background:#0f1115; color:#e6e8ee; margin:0; padding:24px; }}
  h1    {{ margin:0 0 4px 0; }}
  .meta {{ color:#8b93a7; font-size:13px; margin-bottom:24px; }}
  .card {{ background:#1a1d24; border:1px solid #2a2f3a; border-radius:10px; padding:18px 22px; margin-bottom:20px; }}
  h2    {{ margin-top:0; display:flex; align-items:center; gap:12px; }}
  h3    {{ margin:18px 0 10px 0; color:#cbd1de; }}
  .badge{{ font-size:12px; padding:3px 10px; border-radius:999px; font-weight:700; letter-spacing:.5px;}}
  .badge.ok  {{ background:#15391f; color:#5fe091; border:1px solid #2a6b3e; }}
  .badge.bad {{ background:#3b1414; color:#ff7373; border:1px solid #6e2828; }}
  .badge.muted{{background:#222731; color:#94a0b6; border:1px solid #3a4151; }}
  .ok  {{ color:#5fe091; }}
  .bad {{ color:#ff7373; }}
  .muted{{color:#8b93a7;}}
  .kpis{{ display:grid; grid-template-columns:repeat(6,1fr); gap:10px; margin:6px 0 4px 0; }}
  .kpi {{ background:#11141b; padding:10px 12px; border-radius:8px; border:1px solid #242936; text-align:center; }}
  .kpi .num{{ font-size:22px; font-weight:700; }}
  .kpi.ok  .num{{color:#5fe091;}}
  .kpi.bad .num{{color:#ff7373;}}
  table {{ width:100%; border-collapse:collapse; margin-top:8px; background:#11141b; border-radius:8px; overflow:hidden; }}
  th,td {{ padding:8px 12px; text-align:left; border-bottom:1px solid #242936; font-size:14px; }}
  th    {{ background:#222731; }}
  .cov-grid{{ display:grid; grid-template-columns:repeat(2,1fr); gap:10px; }}
  .cov-item{{ background:#11141b; padding:10px 12px; border-radius:8px; border:1px solid #242936; }}
  .cov-label{{font-size:12px; color:#8b93a7; margin-bottom:6px;}}
  .cov-bar  {{height:8px; background:#222731; border-radius:4px; overflow:hidden;}}
  .cov-fill {{height:100%; background:linear-gradient(90deg,#3aa66a,#5fe091);}}
  .cov-val  {{font-size:13px; margin-top:4px; text-align:right; color:#cbd1de;}}
  code  {{font-family:ui-monospace,Consolas,monospace;}}
</style></head><body>
  <h1>Memory Controller — Verification Dashboard</h1>
  <div class="meta">Generated {ts}</div>
  {cards}
</body></html>"""

    with open(OUT_FILE, "w", encoding="utf-8") as f:
        f.write(page)
    print(f"Dashboard written: {OUT_FILE}")


if __name__ == "__main__":
    main()