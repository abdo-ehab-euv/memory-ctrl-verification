# Memory Controller Verification

Two-tier SystemVerilog verification of an 8-location × 8-bit SRAM controller.
Built as a hardware-verification portfolio project for HAV / DV internships.

- **Simple flow** (`tb/simple/`) — original task-based testbench. Runs on free
  ModelSim Intel Starter Edition. Great for showing the basics.
- **UVM flow** (`tb/uvm/`) — full UVM environment with sequencer, driver,
  monitor, scoreboard, functional coverage. Requires Questa or any
  UVM-capable simulator.
- **Bug demo** — a buggy DUT (`rtl/memory_ctrl_buggy.sv`) demonstrates the
  scoreboard catching a real failure end-to-end.
- **Python tooling** — `regression.py` parses logs and produces a CI-friendly
  exit code; `dashboard.py` produces `reports/dashboard.html` summarising
  pass/fail and coverage.

## Folder structure

```text
memory-ctrl-verification/
├── .github/
│   └── workflows/
│       └── regression.yml
├── docs/
│   ├── img/
│   │   ├── bug_run_dashboard.png
│   │   ├── clean_run_dashboard.png
│   │   ├── waveform_addr7_bug.png
│   │   └── waveform_reset.png
│   ├── architecture.md
│   ├── results_template.md
│   └── verification_plan.md
├── reports/
│   └── .gitkeep
├── rtl/
│   ├── memory_ctrl.sv
│   └── memory_ctrl_buggy.sv
├── scripts/
│   ├── clean.ps1
│   ├── run_simple.tcl
│   ├── run_uvm.tcl
│   └── run_uvm_bug.tcl
├── tb/
│   ├── simple/
│   │   ├── mem_test.sv
│   │   └── tb_top.sv
│   └── uvm/
│       ├── mem_agent.sv
│       ├── mem_base_test.sv
│       ├── mem_coverage.sv
│       ├── mem_driver.sv
│       ├── mem_env.sv
│       ├── mem_if.sv
│       ├── mem_monitor.sv
│       ├── mem_scoreboard.sv
│       ├── mem_seq_item.sv
│       ├── mem_sequence.sv
│       ├── mem_uvm_pkg.sv
│       └── tb_top_uvm.sv
├── tools/
│   ├── dashboard.py
│   └── regression.py
├── .gitignore
├── README.md
└── requirements.txt
```text

## Simulator requirements

| Flow            | Simulator                                   |
|-----------------|---------------------------------------------|
| Simple          | ModelSim Intel Starter (free) **or** Questa |
| UVM             | Questa / Riviera-PRO / VCS / Xcelium        |
| UVM bug demo    | same as UVM                                 |

Free ModelSim Intel Starter does not ship `uvm_pkg`, so the UVM flow needs Questa.

## Run commands (PowerShell, from repo root)

```powershell
cd path\to\memory-ctrl-verification

# 1) Simple flow (original)
vsim -c -do scripts/run_simple.tcl
python tools/regression.py reports/simple_sim_log.txt

# 2) UVM clean run — should be all PASS
vsim -c -do scripts/run_uvm.tcl
python tools/regression.py reports/uvm_sim_log.txt

# 3) UVM bug demo — should fail at addr 7
vsim -c -do scripts/run_uvm_bug.tcl
python tools/regression.py reports/uvm_bug_log.txt

# 4) HTML dashboard summarising both UVM runs
python tools/dashboard.py reports/uvm_sim_log.txt reports/uvm_bug_log.txt

# 5) Clean build artefacts
powershell -ExecutionPolicy Bypass -File scripts/clean.ps1
```

(Linux/macOS: same commands, swap `python` for `python3` and the cleanup line for `rm -rf work transcript reports/*.txt waveform.vcd`.)

## How the bug demo works

`rtl/memory_ctrl_buggy.sv` corrupts writes to address 7 only — it stores
`din ^ 0xFF` instead of `din`. The clean run touches every address and
every data class so the bug is **guaranteed** to be hit:
- the directed sequence's boundary phase writes 0x00 and 0xFF to all 8 addresses,
- the random sequence (≥100 transactions) hits addr 7 multiple times.

The scoreboard records each FAIL with `expected=0xXX actual=0xYY`; the
dashboard surfaces the offending checks under "Failing checks".

## Screenshots

### Clean Regression Dashboard

![Clean run dashboard](docs/img/clean_run_dashboard.png)

### Bug Regression Dashboard

![Bug run dashboard](docs/img/bug_run_dashboard.png)

### Clean Reset Waveform

![Clean reset waveform](docs/img/waveform_reset.png)

### Intentional Address-7 Bug Waveform

![Address 7 bug waveform](docs/img/waveform_addr7_bug.png)

In the bug waveform, the DUT stores the corrupted value at address 7 while the testbench shadow memory keeps the expected value, so the self-checking testbench increments `fail_count`.

## What this project demonstrates

- SystemVerilog RTL (synchronous write / combinational read / async reset).
- A self-checking testbench with a shadow-memory reference model.
- Full UVM architecture: sequencer/driver/monitor/scoreboard/coverage/agent/env/test.
- Constrained-random stimulus and directed corner cases.
- Functional coverage with covergroups, cross coverage, and transition coverage.
- TCL automation, log parsing, HTML reporting.
- A reproducible bug-injection / detection / fix loop.

## Troubleshooting

- **`Error: (vlog-2163) ... 'uvm_pkg' could not be found`** — your simulator doesn't have UVM. Use Questa or recompile UVM source against ModelSim manually.
- **`# ** Error (suppressible): ... 'uvm_macros.svh' not found`** — `+incdir+tb/uvm` is missing from `vlog`. Use the provided TCL script.
- **Dashboard says "Log file not found"** — run the corresponding TCL script before `dashboard.py`.
- **All UVM reads PASS but `regression.py` exits 1** — there's a stray `UVM_ERROR` somewhere; open the log and search for `UVM_ERROR`.
- **Self-hosted CI never runs** — the SV job in `regression.yml` is gated by `if: false`. Flip it after registering a runner.