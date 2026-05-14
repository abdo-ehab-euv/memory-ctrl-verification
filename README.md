# SystemVerilog UVM Verification of an SRAM Memory Controller

> **Block-level UVM verification environment for an 8×8 SRAM controller — featuring constrained-random stimulus, a shadow-memory scoreboard, functional coverage with cross and transition bins, regression automation with Python-based log parsing, and an intentional bug-injection flow that proves the environment catches real silicon-like failures.**

[![regression](https://github.com/abdo-ehab-euv/sram-controller-uvm-verification/actions/workflows/regression.yml/badge.svg)](https://github.com/abdo-ehab-euv/sram-controller-uvm-verification/actions/workflows/regression.yml)
![SystemVerilog](https://img.shields.io/badge/language-SystemVerilog%20%7C%20UVM-blue)

---

## Project Highlights

| Aspect                      | Detail                                                                                                 |
| --------------------------- | ------------------------------------------------------------------------------------------------------ |
| **DUT**                     | 8-location × 8-bit synchronous-write / combinational-read SRAM controller                              |
| **Verification Methodology**| UVM 1.2 (test → env → agent → sequencer / driver / monitor → scoreboard / coverage)                    |
| **Language**                | SystemVerilog (RTL + testbench) · Python 3 (regression & dashboard) · TCL (simulation automation)      |
| **Simulator**               | Questa (UVM flow) · ModelSim Intel Starter (simple flow)                                               |
| **UVM Architecture**        | Full agent with sequencer, driver, monitor; scoreboard with shadow-memory reference model; coverage subscriber |
| **Stimulus**                | Directed sequences · boundary-value sequences · sequential-pattern sequences · constrained-random (100–200 transactions) |
| **Checking**                | Self-checking scoreboard with `shadow_mem[0:7]` reference model; PASS/FAIL printed per read check      |
| **Coverage**                | Address bins (0–7) · operation bins (read/write) · data-class bins · address×operation cross · address-transition coverage |
| **Automation**              | TCL compile-and-run scripts · `regression.py` log parser · `dashboard.py` HTML report · GitHub Actions CI |
| **Debug Evidence**          | Intentional buggy DUT (`memory_ctrl_buggy.sv`) · scoreboard-caught mismatches · clean vs. failing dashboard · waveform screenshots |

---

## Why This Project Matters

This project demonstrates the core block-level verification skills used in ASIC and FPGA DV roles:

- **Reading a specification** and translating features into a verification plan with measurable coverage goals.
- **Architecting a UVM environment** from scratch — sequence items, sequences, driver, monitor, agent, scoreboard, coverage subscriber, environment, and test.
- **Generating diverse stimulus** — directed corner-case tests, boundary-value sweeps, sequential address patterns, and constrained-random traffic.
- **Building a self-checking scoreboard** that uses a reference model to automatically detect DUT mismatches without manual waveform inspection.
- **Defining functional coverage** with coverpoints, cross coverage, and transition bins to measure verification completeness.
- **Automating regression** with TCL scripts and Python-based log parsing that produce CI-friendly exit codes and an HTML dashboard.
- **Injecting and debugging real bugs** — proving the verification environment catches failures, not just passing tests.

---

## DUT Overview

The design under test is a minimal SRAM controller (`rtl/memory_ctrl.sv`):

| Property | Value                                                       |
| -------- | ----------------------------------------------------------- |
| Depth    | 8 locations                                                 |
| Width    | 8 bits                                                      |
| Write    | Synchronous — captured on `posedge clk` when `we == 1`      |
| Read     | Combinational — `dout = mem[addr]`                          |
| Reset    | Active-low asynchronous — clears all 8 locations to `8'h00` |
| Ready    | `ready = 0` during reset, `ready = 1` after reset release   |

Port list: `clk`, `rst_n`, `we`, `addr[2:0]`, `din[7:0]`, `dout[7:0]`, `ready`.

The focus of this project is the **verification environment**, not the RTL complexity.

---

## UVM Testbench Architecture

```
tb_top_uvm
 ├── clk_gen (10 MHz, always #50 toggle)
 ├── mem_if  (SystemVerilog interface + tb_valid handshake signal)
 ├── DUT: memory_ctrl  /  memory_ctrl_buggy  (selected via +define+USE_BUGGY_DUT)
 └── UVM
     └── mem_base_test
         └── mem_env
             ├── mem_agent
             │   ├── mem_sequencer  (uvm_sequencer #(mem_seq_item))
             │   ├── mem_driver     (drives we/addr/din, pulses tb_valid)
             │   └── mem_monitor    (samples on posedge clk + 1ns when tb_valid == 1)
             ├── mem_scoreboard     (shadow_mem reference model, PASS/FAIL per read)
             └── mem_coverage       (covergroups: address, operation, data, cross, transitions)
```

### Transaction Flow

```
Sequence ──→ Sequencer ──→ Driver ──→ mem_if ──→ DUT
                                        │
                                    Monitor (analysis port)
                                     ╱          ╲
                              Scoreboard     Coverage
```

### Key UVM Mechanisms

| Mechanism                           | Usage in This Project                                                           |
| ----------------------------------- | ------------------------------------------------------------------------------- |
| `uvm_config_db#(virtual mem_if)`    | Virtual interface distribution from `tb_top_uvm` to driver and monitor          |
| `uvm_analysis_port` / `uvm_analysis_imp` | Monitor broadcasts observed transactions to scoreboard and coverage        |
| `uvm_subscriber`                    | `mem_coverage` extends `uvm_subscriber#(mem_seq_item)` for automatic analysis port connection |
| `run_test("mem_base_test")`         | Called from `tb_top_uvm` initial block to launch UVM phasing                    |
| `phase.raise_objection / drop_objection` | Controls simulation end-of-test in `mem_base_test`                         |
| `` `uvm_do_with `` / `` `uvm_do `` | Inline sequence item creation with constraints in all sequences                 |

---

## Verification Plan

| Feature ID | DUT Feature                    | Test Strategy                                                         | Checker / Coverage                           |
| ---------- | ------------------------------ | --------------------------------------------------------------------- | -------------------------------------------- |
| F1         | 8-location × 8-bit memory     | T2: write all 8 addrs with distinct data, read all back               | `cp_addr` bins 0–7 (100% goal)               |
| F2         | Synchronous write (`posedge`)  | T1: write 0xFF to addr 0, read back; T3: triple overwrite addr 3      | Scoreboard `shadow_mem` update on every write |
| F3         | Combinational read             | Every read transaction checked by scoreboard                          | `cp_op` read\_op bin                         |
| F4         | Active-low async reset         | T4: reset after writes, confirm 0x00; T5: read all addrs after reset  | Scoreboard shadow reset to 0x00              |
| F5         | `ready` behavior               | T4/T5: reset sequence confirms ready transitions                     | Visual waveform evidence                     |
| —          | Boundary data values           | `mem_directed_seq`: 0x00 and 0xFF written to all 8 addresses          | `cp_data` zero / all\_ones bins              |
| —          | Overwrite correctness          | T3: three consecutive writes to addr 3, read confirms latest value    | Scoreboard comparison                        |
| —          | Sequential access pattern      | `mem_sequential_seq`: ascending write 0–7, then ascending read 0–7    | `cp_trans` same\_addr / diff\_addr bins      |
| —          | Constrained-random traffic     | `mem_random_seq`: 100–200 randomized read/write transactions          | `cross_addr_op` cross coverage               |
| —          | Bug scenario at address 7      | `run_uvm_bug.tcl` with `memory_ctrl_buggy.sv`                        | Scoreboard FAIL + `uvm_error`                |

> See [`docs/verification_plan.md`](docs/verification_plan.md) for the full formal verification plan.

---

## Stimulus Strategy

### Directed Tests — `mem_directed_seq`

- **T1**: Write `0xFF` to address 0, read back — basic write/read sanity.
- **T2**: Write addresses 0–7 with data `0xA0 + i`, read all back — full address range.
- **T3**: Triple overwrite address 3 (`0x11 → 0x22 → 0x33`), read back — latest-value correctness.
- **Boundary sweep**: Write `0x00` then `0xFF` to every address and read back — boundary data coverage.

### Sequential Pattern — `mem_sequential_seq`

- Ascending writes: address 0 → 7 with data `0x10 + i`.
- Ascending reads: address 0 → 7 — verifies data integrity in order.
- Exercises address-transition coverage (`same_addr` / `diff_addr` bins).

### Constrained-Random — `mem_random_seq`

- Generates 100–200 fully random transactions (controlled by `constraint c_n`).
- `addr ∈ [0:7]`, `din ∈ [0:255]`, `we` randomly toggled via `rand bit`.
- Each read is automatically checked by the scoreboard — no manual expected values needed.
- `mem_base_test` overrides `n_trans` to 120 via inline randomize constraint.

### Boundary / Corner Tests

- `0x00` and `0xFF` are explicitly written to all 8 addresses in the directed sequence.
- These exercise the `cp_data` zero and all\_ones coverage bins.
- On the buggy DUT, `0x00` to addr 7 stores `0xFF` and vice versa — immediately caught by the scoreboard.

---

## Scoreboard Strategy

The scoreboard (`mem_scoreboard`) is the central self-checking component. It uses a **shadow memory** as a transaction-level reference model:

```
┌───────────────────────────────────────────────────────────┐
│                    mem_scoreboard                         │
│                                                           │
│   bit [7:0] shadow_mem [0:7]    ← initialized to 0x00    │
│                                                           │
│   On write transaction:                                   │
│     shadow_mem[addr] = din      ← update reference        │
│                                                           │
│   On read transaction:                                    │
│     if (dout === shadow_mem[addr])                         │
│       → PASS, increment pass_count                        │
│     else                                                  │
│       → FAIL, increment fail_count                        │
│       → uvm_error with expected=0xNN actual=0xNN          │
│                                                           │
│   report_phase:                                           │
│     SCOREBOARD_SUMMARY total=N pass=N fail=N              │
└───────────────────────────────────────────────────────────┘
```

**Key design decisions:**

- The scoreboard subscribes to the monitor's `uvm_analysis_port` via `uvm_analysis_imp`, receiving every observed transaction automatically.
- The `write()` function determines read vs. write by checking `t.we`.
- Each read check is given a unique name (`read_chk<N>_addr<N>`) for traceability in logs.
- Mismatches use `uvm_error` (not `uvm_fatal`) so the simulation continues and all failures are collected.
- `fail_count` is used by `regression.py` to determine the overall pass/fail status.
- PASS/FAIL output format is regex-friendly, enabling automated log parsing.

---

## Functional Coverage

The coverage subscriber (`mem_coverage`) extends `uvm_subscriber#(mem_seq_item)` and contains two covergroups:

### `cg_mem` — Main Covergroup

| Coverpoint      | Bins                                                                  | Goal |
| --------------- | --------------------------------------------------------------------- | ---- |
| `cp_addr`       | `{0, 1, 2, 3, 4, 5, 6, 7}` — one bin per address                    | 100% |
| `cp_op`         | `write_op = {1}`, `read_op = {0}`                                    | 100% |
| `cp_data`       | `zero = {0x00}`, `all_ones = {0xFF}`, `low_mid = {0x01:0x7F}`, `high_mid = {0x80:0xFE}` | 100% |
| `cross_addr_op` | Cross of `cp_addr` × `cp_op` (16 bins total)                         | 100% |

### `cg_addr_trans` — Address Transition Covergroup

| Coverpoint  | Bins                                                              | Goal |
| ----------- | ----------------------------------------------------------------- | ---- |
| `cp_trans`  | `same_addr` (previous == current), `diff_addr` (previous ≠ current) | 100% |

**Coverage reporting**: In `report_phase`, individual coverpoint percentages and a computed overall average are printed in a `COVERAGE_REPORT` line that `dashboard.py` parses with a regex to populate the HTML coverage bars.

> **Note**: This project implements *functional coverage* (specification-driven). *Code coverage* (line/toggle/FSM) requires simulator-specific flags (e.g., `vsim -coverage`) and is not collected in the current flow. Adding code coverage collection is listed as a future improvement.

---

## Bug-Injection Demo

A key strength of this project is **proving the environment actually catches bugs**, not just passing clean runs.

### The Bug

`rtl/memory_ctrl_buggy.sv` contains an intentional corruption:

```systemverilog
if (addr == 3'd7)
    mem[addr] <= din ^ 8'hFF;   // data is bit-inverted at address 7
else
    mem[addr] <= din;            // all other addresses are correct
```

### What Happens

| Scenario                        | DUT Used             | Expected Result                                                    |
| ------------------------------- | -------------------- | ------------------------------------------------------------------ |
| Clean regression (`run_uvm.tcl`)| `memory_ctrl`        | All PASS — scoreboard `fail_count == 0`                            |
| Bug regression (`run_uvm_bug.tcl`)| `memory_ctrl_buggy`| FAIL at address 7 — scoreboard reports `expected=0xNN actual=0xNN` |

### Why This Matters

- The **directed sequence** writes `0x00` and `0xFF` to all 8 addresses — address 7 is guaranteed to be hit, triggering corrupted values `0xFF` and `0x00`.
- The **random sequence** (120 transactions) statistically hits address 7 multiple times.
- The **scoreboard** catches every mismatch and reports it with expected/actual values.
- The **dashboard** surfaces failing checks under a red FAIL badge, making triage immediate.
- This demonstrates a real **detect → debug → fix** workflow used in industry DV.

---

## Results

| Run                  | Script            | DUT Used             | Expected Outcome                              | Evidence                |
| -------------------- | ----------------- | -------------------- | --------------------------------------------- | ----------------------- |
| Simple testbench     | `run_simple.tcl`  | `memory_ctrl`        | All PASS (directed T1–T5 + 50 random ops)     | Console log             |
| UVM clean regression | `run_uvm.tcl`     | `memory_ctrl`        | All PASS, `fail_count == 0`                   | Dashboard screenshot    |
| UVM bug regression   | `run_uvm_bug.tcl` | `memory_ctrl_buggy`  | FAIL at address 7, `fail_count > 0`           | Dashboard screenshot    |
| HTML dashboard       | `dashboard.py`    | —                    | Generates `reports/dashboard.html`            | Screenshot below        |

> **Note**: Coverage percentages and exact check counts depend on the simulator run. The screenshots below are from actual Questa runs — no results are fabricated.

### Clean Regression Dashboard

![Clean run dashboard — all checks PASS, coverage bars at 100%](docs/img/clean_run_dashboard.png)

### Bug Regression Dashboard

![Bug run dashboard — address 7 checks FAIL, failing checks listed](docs/img/bug_run_dashboard.png)

### Waveform — Clean Reset Behavior

![Waveform showing reset clears all memory locations to 0x00 and ready transitions](docs/img/waveform_reset.png)

### Waveform — Address 7 Bug Caught

![Waveform showing corrupted data at address 7 — shadow memory vs. DUT mismatch](docs/img/waveform_addr7_bug.png)

In the bug waveform, the DUT stores `din ^ 0xFF` at address 7 while the scoreboard's shadow memory holds the correct expected value, causing `fail_count` to increment.

---

## How to Run

> **Requirements**: Questa (for UVM flow) or ModelSim Intel Starter (for simple flow only). Python 3.x with `tabulate` (`pip install -r requirements.txt`).

### Simple Flow (No UVM Required)

```powershell
vsim -c -do scripts/run_simple.tcl
python tools/regression.py reports/simple_sim_log.txt
```

### UVM Clean Regression

```powershell
vsim -c -do scripts/run_uvm.tcl
python tools/regression.py reports/uvm_sim_log.txt
```

### UVM Bug Demo

```powershell
vsim -c -do scripts/run_uvm_bug.tcl
python tools/regression.py reports/uvm_bug_log.txt
```

### HTML Dashboard

```powershell
python tools/dashboard.py reports/uvm_sim_log.txt reports/uvm_bug_log.txt
# Open reports/dashboard.html in a browser
```

### Cleanup

```powershell
# Windows PowerShell
powershell -ExecutionPolicy Bypass -File scripts/clean.ps1

# Linux / macOS
rm -rf work transcript reports/*.txt waveform.vcd
```

### Using the Makefile

```bash
make simple       # Simple testbench
make uvm          # UVM clean regression
make bug          # UVM bug-injection regression
make dashboard    # Generate HTML dashboard
make clean        # Remove simulation artifacts
```

---

## Repository Structure

```
sram-controller-uvm-verification/
├── rtl/
│   ├── memory_ctrl.sv              # Clean golden DUT
│   └── memory_ctrl_buggy.sv        # Intentionally buggy DUT (addr 7 corruption)
├── tb/
│   ├── simple/                     # Task-based testbench (no UVM)
│   │   ├── tb_top.sv
│   │   └── mem_test.sv
│   └── uvm/                        # Full UVM environment
│       ├── mem_seq_item.sv          # Transaction class
│       ├── mem_sequence.sv          # Directed, random, sequential sequences
│       ├── mem_driver.sv            # Drives transactions onto mem_if
│       ├── mem_monitor.sv           # Observes DUT via analysis port
│       ├── mem_scoreboard.sv        # Shadow-memory reference model + checker
│       ├── mem_coverage.sv          # Functional coverage subscriber
│       ├── mem_agent.sv             # Bundles sequencer/driver/monitor
│       ├── mem_env.sv               # Top-level UVM environment
│       ├── mem_base_test.sv         # Default test: directed → sequential → random
│       ├── mem_if.sv                # SystemVerilog interface
│       ├── mem_uvm_pkg.sv           # Package with compile-order includes
│       └── tb_top_uvm.sv            # Testbench top module
├── scripts/
│   ├── run_simple.tcl               # TCL: compile + simulate simple flow
│   ├── run_uvm.tcl                  # TCL: compile + simulate UVM clean
│   ├── run_uvm_bug.tcl              # TCL: compile + simulate UVM with buggy DUT
│   └── clean.ps1                    # PowerShell cleanup script
├── tools/
│   ├── regression.py                # Log parser with CI exit codes (0/1/2)
│   └── dashboard.py                 # HTML dashboard generator
├── docs/
│   ├── verification_plan.md         # Formal verification plan
│   ├── architecture.md              # UVM architecture documentation
│   ├── results_template.md          # Run-results recording template
│   └── img/                         # Dashboard + waveform screenshots
├── reports/                         # Simulation logs + dashboard output
├── .github/workflows/regression.yml # CI: Python checks + repo structure validation
├── .editorconfig                    # Editor formatting rules
├── Makefile                         # Convenience targets (make uvm, make bug, etc.)
├── .gitignore                       # Ignore simulator artifacts
└── requirements.txt                 # Python dependencies (tabulate)
```

---

## CI / Continuous Integration

| What CI Does                                    | How                                                                   |
| ----------------------------------------------- | --------------------------------------------------------------------- |
| Python syntax check                             | `py_compile` on `regression.py` and `dashboard.py`                    |
| Repo structure validation                       | Verifies all expected files exist                                     |
| Dashboard generation smoke test                 | Runs tools against a synthetic log, confirms HTML output              |
| Dashboard artifact upload                       | Uploads `reports/dashboard.html` as a downloadable CI artifact        |

**Honest note on simulation**: GitHub-hosted runners do **not** include Questa or ModelSim (commercial licensed tools). The actual SystemVerilog regression requires a self-hosted runner with a licensed simulator. A disabled skeleton job for self-hosted Questa execution is included in the workflow file.

---

## DV Skills Demonstrated

- SystemVerilog RTL design and testbench development
- UVM component architecture (test → env → agent → sequencer / driver / monitor)
- Transaction-level modeling (`uvm_sequence_item`)
- Self-checking scoreboard with shadow-memory reference model
- Functional coverage with coverpoints, cross coverage, and transition bins
- Constrained-random verification methodology
- Directed and boundary-value test development
- Regression automation with TCL and Python
- Log parsing and CI exit-code generation
- HTML dashboard generation for results visualization
- Bug injection and failure triage workflow
- Waveform-based debug (VCD dump)
- `uvm_config_db` virtual interface distribution
- Analysis port / analysis imp communication pattern

---

## Interview Talking Points

- **Why UVM?** UVM provides a standardized, reusable verification methodology. The class-based architecture allows the same environment to be reused across different tests and extended for more complex DUTs without rewriting infrastructure.

- **How does the scoreboard work?** It maintains a `shadow_mem[0:7]` array that mirrors the DUT's expected state. Every write updates the shadow; every read compares `dout` against the shadow. This is a transaction-level reference model — the simplest form of the predict-and-compare pattern used in industry scoreboards.

- **How does coverage map to the verification plan?** Each coverpoint directly traces to a DUT feature: `cp_addr` ensures all 8 locations are exercised (F1), `cp_op` ensures both reads and writes are tested (F2/F3), `cross_addr_op` ensures every address is both read and written, and `cp_trans` ensures back-to-back address patterns are covered.

- **How does the bug demo prove the environment?** The buggy DUT corrupts writes to address 7 (`din ^ 0xFF`). The scoreboard catches every mismatch with expected/actual values. If the environment only passed clean tests, it could be a trivially permissive checker — the bug demo proves it has real detection capability.

- **What would change at industry scale?** A real block-level environment would add SystemVerilog Assertions (SVA) for protocol checks, code coverage (line/toggle/FSM) merged with functional coverage, a register model (UVM RAL) for register-mapped interfaces, negative/error-injection tests, and multiple test classes extending a common base test.

---

## Future Improvements

- **SystemVerilog Assertions (SVA)**: Add inline assertions for reset behavior, ready protocol, and write-to-read latency.
- **Code coverage**: Enable simulator code coverage (line, toggle, FSM) and merge with functional coverage reports.
- **APB or AXI-Lite wrapper**: Wrap the SRAM controller with a standard bus interface to demonstrate protocol-level verification.
- **Negative / error tests**: Add tests for out-of-range addresses, writes during reset, and back-pressure scenarios.
- **Reusable UVM package structure**: Refactor into a proper `uvm_pkg` with parameterized components for reuse across different memory sizes.
- **Self-hosted GitHub Actions**: Configure a self-hosted runner with Questa for automated SV regression in CI.
- **Coverage database export**: Export UCDB/coverage databases for merging across multiple test runs.
- **Waveform automation**: Add TCL scripts for automated waveform capture and annotation.

---

## CV / Résumé Bullets

> **SRAM Controller UVM Verification** — Designed and implemented a complete UVM verification environment for an 8×8 SRAM controller, including constrained-random stimulus generation, a self-checking shadow-memory scoreboard, and functional coverage with cross and transition bins; automated regression with Python-based log parsing and HTML dashboard generation.

> **Bug-Injection Verification Flow** — Developed an intentional-bug injection methodology to validate environment detection capability; demonstrated end-to-end detect → debug → fix workflow with scoreboard-caught mismatches, automated regression reporting, and waveform-based root-cause analysis.

---

<p align="center"><i>SystemVerilog · UVM · Questa</i></p>