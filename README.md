# Memory Controller Verification (SystemVerilog + Python)

A compact, **self-checking** SystemVerilog testbench for an 8-location × 8-bit
SRAM memory controller. Directed tests, 50-op constrained-random stimulus,
ModelSim TCL automation, and a Python regression tool that emits an HTML
report. Built as a one-day HAV/DV sprint project.

---

## Project overview

The DUT is a tiny SRAM controller:

- 8 locations × 8 bits
- Synchronous write, combinational read
- Active-low reset clears memory to `0x00`

The testbench maintains a **shadow memory array** that mirrors every write.
After every read it asserts `dout === shadow_mem[addr]` and prints a
machine-parseable `PASS`/`FAIL` line. `regression.py` parses those lines,
renders a terminal table, writes `report.html`, and exits with a non-zero
status on any failure.

---

## File list

| File                | Purpose                                                     |
| ------------------- | ----------------------------------------------------------- |
| `memory_ctrl.sv`    | RTL DUT (supports `+define+INJECT_BUG` for debug practice)  |
| `tb_top.sv`         | Testbench top: clock, reset, DUT instance, VCD dump         |
| `mem_test.sv`       | Directed + random tests, helper tasks (SV-include file)     |
| `run_sim.tcl`       | Clean ModelSim flow — all tests should PASS                 |
| `run_bug_sim.tcl`   | Buggy flow (`+define+INJECT_BUG`) — expected failures       |
| `regression.py`     | Log parser → terminal table + `report.html`                 |
| `README.md`         | This file                                                   |

---

## Architecture (ASCII)