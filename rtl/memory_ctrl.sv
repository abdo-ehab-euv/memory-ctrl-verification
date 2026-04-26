// ============================================================
// memory_ctrl.sv
// 8-location x 8-bit SRAM memory controller (DUT)
// ------------------------------------------------------------
// - Synchronous write (posedge clk)
// - Combinational read
// - Active-low async reset clears all memory to 8'h00
// - ready = 0 in reset, 1 after reset release
// - Compile with +define+INJECT_BUG to enable the subtle bug
//   used for debug practice with regression.py
// ============================================================
`timescale 1ns/1ps

module memory_ctrl (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       we,
    input  logic [2:0] addr,
    input  logic [7:0] din,
    output logic [7:0] dout,
    output logic       ready
);

    // Internal memory
    logic [7:0] mem [0:7];

    // Synchronous write + reset logic
    always_ff @(posedge clk or negedge rst_n) begin : mem_write
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
`ifdef INJECT_BUG
                // ---- INTENTIONAL BUG ----
                // For addr == 3'd5 the controller writes to (addr+1)
                // instead of addr. All other addresses behave correctly.
                // This makes T2 fail at addr 5, and some random ops fail,
                // while most tests still pass. Great for debug practice.
                if (addr == 3'd5)
                    mem[addr + 3'd1] <= din;
                else
                    mem[addr]        <= din;
`else
                mem[addr] <= din;
`endif
            end
        end
    end

    // Combinational read
    assign dout = mem[addr];

endmodule