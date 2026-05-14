# Verification Plan — SRAM Memory Controller

## 1. DUT Feature List

| ID  | Feature                                        |
| --- | ---------------------------------------------- |
| F1  | 8-location × 8-bit memory                     |
| F2  | Synchronous write on `posedge clk`             |
| F3  | Combinational read on `addr`                   |
| F4  | Active-low async reset clears memory to `0x00` |
| F5  | `ready` low in reset, high after release       |

## 2. Test List

### Directed (UVM `mem_directed_seq` and simple T1–T5)

| Test      | Targets  | Description                                |
| --------- | -------- | ------------------------------------------ |
| T1        | F1,F2,F3 | Write `0xFF` to addr 0, read back          |
| T2        | F1,F2,F3 | Write all 8 addresses, read all back       |
| T3        | F2       | Triple-overwrite addr 3, confirm latest    |
| T4        | F4       | Reset after writes, confirm cleared        |
| T5        | F4       | Read every address after reset → all `0x00`|
| Tboundary | F2,F3    | Boundary data `0x00` / `0xFF` on every address |

### Constrained-Random (`mem_random_seq`)

- ≥100 transactions per run.
- `addr` ∈ [0:7], `din` ∈ [0:255], `we` random.
- Self-checked by scoreboard against shadow memory.

### Sequential Pattern (`mem_sequential_seq`)

- Writes 0–7 in order, then reads 0–7.
- Exercises ascending address transitions.

## 3. Coverage Goals (`mem_coverage`)

| Coverpoint      | Bins                                         | Goal |
| --------------- | -------------------------------------------- | ---- |
| `cp_addr`       | 0, 1, …, 7                                  | 100% |
| `cp_op`         | write\_op, read\_op                          | 100% |
| `cp_data`       | zero(0x00), all\_ones(0xFF), low\_mid, high\_mid | 100% |
| `cross_addr_op` | every address × {read, write}                | 100% |
| `cp_trans`      | same\_addr, diff\_addr                       | 100% |

Closure expected at end of `mem_base_test`.

## 4. Scoreboard Strategy

Reference model is a `bit [7:0] shadow_mem [0:7]`.
The scoreboard subscribes to the monitor's analysis port:

- On observed write → `shadow_mem[addr] = din`.
- On observed read → assert `dout === shadow_mem[addr]`.
  PASS / FAIL message printed in a regex-friendly format.

## 5. Pass Criteria

- Zero `UVM_ERROR` and zero `UVM_FATAL`.
- Scoreboard `fail_count == 0`.
- Coverage `overall == 100%` for clean run.

## 6. Bug-Injection Demo

`memory_ctrl_buggy.sv` corrupts writes to addr 7 (`din ^ 0xFF`).
Expected outcome with `run_uvm_bug.tcl`:

- Boundary writes `0x00` / `0xFF` at addr 7 → corrupted to `0xFF` / `0x00`,
  scoreboard FAILs immediately.
- Random reads of addr 7 → multiple FAILs.
- Other addresses still PASS, demonstrating localized failure detection.