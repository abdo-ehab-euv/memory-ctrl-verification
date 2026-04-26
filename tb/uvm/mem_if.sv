// ============================================================
// tb/uvm/mem_if.sv  -  SystemVerilog interface for the DUT.
// Carries DUT signals + a TB-only `tb_valid` flag the driver
// uses to mark transaction boundaries for the monitor.
// ============================================================
`timescale 1ns/1ps

interface mem_if (input logic clk);
    logic       rst_n;
    logic       we;
    logic [2:0] addr;
    logic [7:0] din;
    logic [7:0] dout;
    logic       ready;
    // TB-only signal — NOT connected to the DUT, used only so the
    // monitor knows which clock edges carry a real transaction.
    logic       tb_valid;

    modport DUT (
        input  clk, rst_n, we, addr, din,
        output dout, ready
    );
endinterface