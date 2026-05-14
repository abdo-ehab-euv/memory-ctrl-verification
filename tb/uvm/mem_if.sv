// ============================================================
// tb/uvm/mem_if.sv — SystemVerilog Interface
// ------------------------------------------------------------
// Carries all DUT signals plus a testbench-only handshake
// signal (tb_valid) used to mark real transaction boundaries.
//
// tb_valid is NOT connected to the DUT — it exists solely so
// the monitor can distinguish driver-initiated cycles from
// idle bus activity.
// ============================================================
`timescale 1ns/1ps

interface mem_if (input logic clk);

    // DUT signals
    logic       rst_n;
    logic       we;
    logic [2:0] addr;
    logic [7:0] din;
    logic [7:0] dout;
    logic       ready;

    // Testbench-only signal — marks valid transaction cycles
    // for the monitor. NOT connected to the DUT.
    logic       tb_valid;

    // Modport for DUT connection
    modport DUT (
        input  clk, rst_n, we, addr, din,
        output dout, ready
    );

endinterface