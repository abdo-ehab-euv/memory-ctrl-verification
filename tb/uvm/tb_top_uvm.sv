// ============================================================
// tb/uvm/tb_top_uvm.sv — UVM Testbench Top Module
// ------------------------------------------------------------
// Top-level module that ties together:
//   - Clock generation (10 MHz, period = 100 ns)
//   - Reset sequence (active-low, held for 5 cycles)
//   - DUT instantiation (clean or buggy via +define+USE_BUGGY_DUT)
//   - Interface ↔ DUT wiring
//   - uvm_config_db handoff of virtual interface
//   - run_test() to launch UVM phasing
// ============================================================
`timescale 1ns/1ps

module tb_top_uvm;

    import uvm_pkg::*;
    import mem_uvm_pkg::*;
    `include "uvm_macros.svh"

    // ----------------------------------------------------------
    // Clock generation — 10 MHz (period = 100 ns)
    // ----------------------------------------------------------
    logic clk = 0;
    always #50 clk = ~clk;

    // ----------------------------------------------------------
    // Interface instance
    // ----------------------------------------------------------
    mem_if dut_if (.clk(clk));

    // ----------------------------------------------------------
    // DUT instantiation — selected at compile time
    //   Clean:  vlog ... (default)
    //   Buggy:  vlog ... +define+USE_BUGGY_DUT
    // ----------------------------------------------------------
`ifdef USE_BUGGY_DUT
    memory_ctrl_buggy dut (
        .clk   (clk),
        .rst_n (dut_if.rst_n),
        .we    (dut_if.we),
        .addr  (dut_if.addr),
        .din   (dut_if.din),
        .dout  (dut_if.dout),
        .ready (dut_if.ready)
    );
`else
    memory_ctrl dut (
        .clk   (clk),
        .rst_n (dut_if.rst_n),
        .we    (dut_if.we),
        .addr  (dut_if.addr),
        .din   (dut_if.din),
        .dout  (dut_if.dout),
        .ready (dut_if.ready)
    );
`endif

    // ----------------------------------------------------------
    // Reset sequence and waveform dump
    // ----------------------------------------------------------
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_top_uvm);

        // Assert active-low reset
        dut_if.rst_n    = 0;
        dut_if.we       = 0;
        dut_if.addr     = 0;
        dut_if.din      = 0;
        dut_if.tb_valid = 0;

        // Hold reset for 5 clock cycles
        repeat (5) @(posedge clk);

        // Release reset at negedge for clean timing
        @(negedge clk) dut_if.rst_n = 1;
    end

    // ----------------------------------------------------------
    // Simulation watchdog — hard timeout safety net
    // ----------------------------------------------------------
    initial begin
        #5_000_000;
        `uvm_fatal("TIMEOUT", "Simulation watchdog expired")
    end

    // ----------------------------------------------------------
    // UVM entry point
    // ----------------------------------------------------------
    initial begin
        // Pass virtual interface to all UVM components via config_db
        uvm_config_db#(virtual mem_if)::set(null, "*", "vif", dut_if);

        // Launch UVM phasing — test name from +UVM_TESTNAME plusarg
        run_test("mem_base_test");
    end

endmodule