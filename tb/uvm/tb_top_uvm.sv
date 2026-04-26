// ============================================================
// tb/uvm/tb_top_uvm.sv  -  UVM testbench top.
// Instantiates either memory_ctrl or memory_ctrl_buggy based on
// the +define+USE_BUGGY_DUT switch from the Tcl script.
// ============================================================
`timescale 1ns/1ps

module tb_top_uvm;
    import uvm_pkg::*;
    import mem_uvm_pkg::*;
    `include "uvm_macros.svh"

    // 10 MHz clock
    logic clk = 0;
    always #50 clk = ~clk;

    // Interface
    mem_if dut_if (.clk(clk));

    // DUT selection
`ifdef USE_BUGGY_DUT
    memory_ctrl_buggy dut (
        .clk(clk), .rst_n(dut_if.rst_n), .we(dut_if.we),
        .addr(dut_if.addr), .din(dut_if.din),
        .dout(dut_if.dout), .ready(dut_if.ready)
    );
`else
    memory_ctrl       dut (
        .clk(clk), .rst_n(dut_if.rst_n), .we(dut_if.we),
        .addr(dut_if.addr), .din(dut_if.din),
        .dout(dut_if.dout), .ready(dut_if.ready)
    );
`endif

    // Reset and waveform dump
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_top_uvm);

        dut_if.rst_n = 0;
        dut_if.we = 0; dut_if.addr = 0; dut_if.din = 0; dut_if.tb_valid = 0;
        repeat (5) @(posedge clk);
        @(negedge clk) dut_if.rst_n = 1;
    end

    // Hard timeout safety net
    initial begin
        #5_000_000;
        `uvm_fatal("TIMEOUT", "Simulation watchdog expired")
    end

    // Hand the interface to the env via config_db, then start UVM
    initial begin
        uvm_config_db#(virtual mem_if)::set(null, "*", "vif", dut_if);
        run_test("mem_base_test");
    end
endmodule