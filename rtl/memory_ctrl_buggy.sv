// ============================================================
// rtl/memory_ctrl_buggy.sv  -  INTENTIONALLY BUGGY DUT
// Same ports as memory_ctrl.
// BUG: when writing to addr == 3'd7, the data stored is XORed
// with 0xFF (i.e. inverted). This is a realistic corner-case
// bug: most directed tests pass, T2's last address fails, and
// random reads of addr 7 fail. Designed to be caught by the
// scoreboard + coverage. Use this DUT only via run_uvm_bug.tcl.
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
    logic [7:0] mem [0:7];

    always_ff @(posedge clk or negedge rst_n) begin
        int k;
        if (!rst_n) begin
            ready <= 1'b0;
            for (k = 0; k < 8; k = k + 1) mem[k] <= 8'h00;
        end
        else begin
            ready <= 1'b1;
            if (we) begin
                // -------- INTENTIONAL BUG --------
                if (addr == 3'd7)
                    mem[addr] <= din ^ 8'hFF;   // <-- corrupted write
                else
                    mem[addr] <= din;            // correct for all others
                // ---------------------------------
            end
        end
    end

    assign dout = mem[addr];
endmodule