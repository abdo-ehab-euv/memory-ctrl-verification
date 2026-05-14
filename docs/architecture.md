# UVM Testbench Architecture

## UVM Environment

```
+-----------------------------------------------------------+
|                       tb_top_uvm                          |
|                                                           |
|   clk_gen --> clk                                         |
|   reset   --> rst_n                                       |
|                                                           |
|   uvm_config_db::set("vif" -> dut_if)                    |
|   run_test("mem_base_test")                               |
|                                                           |
|   +---------------------+        +-------------------+   |
|   |       mem_if         |<------>| memory_ctrl /     |   |
|   |  (clk, rst_n, we,   |        | memory_ctrl_buggy |   |
|   |   addr, din, dout,  |        +-------------------+   |
|   |   tb_valid)          |                                |
|   +----------^-----------+                                |
+--------------|--------------------------------------------|
               |
    ___________|_____________
   |                         |
   v                         v
 UVM Environment         Coverage
```

## Simple Environment (Legacy / Educational)

The simple testbench (`tb/simple/`) uses a task-based approach
without UVM. It provides the same self-checking capability via
a shadow memory array inside `tb_top.sv`.

## Data Flow Per Transaction

1. **Sequence** builds a `mem_seq_item` and sends it to the sequencer.
2. **Driver** pops the item, drives `we`/`addr`/`din` and pulses
   `tb_valid` for one cycle.
3. **DUT** samples on `posedge clk`. For writes, `mem[addr]` updates.
   For reads, `dout` is `mem[addr]` combinationally.
4. **Monitor** samples the interface at `posedge clk + 1ns`, only
   when `tb_valid == 1`. It builds a complete `mem_seq_item`
   (including `dout`) and broadcasts on its analysis port.
5. **Scoreboard** updates shadow on writes, checks
   `dout === shadow_mem[addr]` on reads.
6. **Coverage subscriber** samples covergroups on the same item.