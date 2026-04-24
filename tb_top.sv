// ============================================================
// tb_top.sv
// Testbench top: clock gen, reset, DUT instance, VCD dump,
// shadow memory, test orchestrator. Includes mem_test.sv which
// provides all test tasks.
// ============================================================
`timescale 1ns/1ps

module tb_top;

    // -----------------------------
    // DUT I/O signals
    // -----------------------------
    logic       clk;
    logic       rst_n;
    logic       we;
    logic [2:0] addr;
    logic [7:0] din;
    logic [7:0] dout;
    logic       ready;

    // -----------------------------
    // Self-checking infrastructure
    // -----------------------------
    logic [7:0] shadow_mem [0:7];  // Golden reference
    int         pass_count;
    int         fail_count;

    // -----------------------------
    // DUT instance
    // -----------------------------
    memory_ctrl dut (
        .clk   (clk),
        .rst_n (rst_n),
        .we    (we),
        .addr  (addr),
        .din   (din),
        .dout  (dout),
        .ready (ready)
    );

    // -----------------------------
    // 10 MHz clock -> period = 100 ns
    // -----------------------------
    initial clk = 1'b0;
    always  #50 clk = ~clk;

    // -----------------------------
    // Waveform dump (VCD)
    // -----------------------------
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_top);
    end

    // -----------------------------
    // Test tasks (inline include)
    // -----------------------------
    `include "mem_test.sv"

    // -----------------------------
    // Simulation watchdog
    // -----------------------------
    initial begin
        #2000000;  // 2 ms hard limit
        $display("ERROR: simulation timeout reached.");
        $finish;
    end

    // -----------------------------
    // Main stimulus sequence
    // -----------------------------
    initial begin
        int k;

        $display("=============================================");
        $display("  SIMULATION START : Memory Controller TB");
        $display("=============================================");

        // Initial values
        rst_n      = 1'b0;
        we         = 1'b0;
        addr       = 3'd0;
        din        = 8'h00;
        pass_count = 0;
        fail_count = 0;
        for (k = 0; k < 8; k = k + 1) shadow_mem[k] = 8'h00;

        // Hold reset for 5 clock cycles
        repeat (5) @(posedge clk);
        @(negedge clk);
        rst_n = 1'b1;
        $display("[%0t] Reset released. ready=%0b", $time, ready);
        @(posedge clk);

        // -----------------------------
        // Run all tests
        // -----------------------------
        run_all_tests();

        // -----------------------------
        // Final summary (human-readable)
        // -----------------------------
        $display("=============================================");
        $display("  TEST SUMMARY");
        $display("  PASSED : %0d", pass_count);
        $display("  FAILED : %0d", fail_count);
        $display("  TOTAL  : %0d", pass_count + fail_count);
        $display("=============================================");
        $display("  SIMULATION END");
        $display("=============================================");

        $finish;
    end

endmodule