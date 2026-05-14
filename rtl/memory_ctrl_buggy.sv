// ============================================================
// memory_ctrl_buggy.sv — INTENTIONALLY BUGGY DUT
// ------------------------------------------------------------
// Same interface as memory_ctrl.sv (clean golden DUT).
//
// BUG: When writing to addr == 3'd7, the stored data is XORed
//      with 8'hFF (bit-inverted). All other addresses behave
//      correctly. This is a realistic corner-case bug:
//        - Most directed tests still pass.
//        - T2's last address (addr 7) fails.
//        - Random reads hitting addr 7 fail intermittently.
//
// PURPOSE: Used exclusively via run_uvm_bug.tcl to demonstrate
//          that the scoreboard and coverage environment detect
//          real DUT bugs — not just passing tests.
// ============================================================
`timescale 1ns/1ps

module memory_ctrl_buggy (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       we,
    input  logic [2:0] addr,
    input  logic [7:0] din,
    output logic [7:0] dout,
    output logic       ready
);

    // Internal 8×8 memory array
    logic [7:0] mem [0:7];

    // --------------------------------------------------------
    // Synchronous write + asynchronous active-low reset
    // --------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        int k;
        if (!rst_n) begin
            ready <= 1'b0;
            for (k = 0; k < 8; k = k + 1) begin
                mem[k] <= 8'h00;
            end
        end
        else begin
            ready <= 1'b1;
            if (we) begin
                // ======== INTENTIONAL BUG ========
                // Address 7 stores inverted data; all other addresses correct.
                if (addr == 3'd7)
                    mem[addr] <= din ^ 8'hFF;   // <-- corrupted write
                else
                    mem[addr] <= din;            // correct for all others
                // =================================
            end
        end
    end

    // --------------------------------------------------------
    // Combinational read
    // --------------------------------------------------------
    assign dout = mem[addr];

endmodule