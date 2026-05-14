// ============================================================
// memory_ctrl.sv — Clean Golden DUT
// 8-location × 8-bit SRAM memory controller
// ------------------------------------------------------------
// - Synchronous write  (posedge clk)
// - Combinational read (dout = mem[addr])
// - Active-low asynchronous reset clears all memory to 8'h00
// - ready = 0 during reset, 1 after reset release
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

    // Internal 8×8 memory array
    logic [7:0] mem [0:7];

    // --------------------------------------------------------
    // Synchronous write + asynchronous active-low reset
    // --------------------------------------------------------
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
                mem[addr] <= din;
            end
        end
    end

    // --------------------------------------------------------
    // Combinational read — output follows addr immediately
    // --------------------------------------------------------
    assign dout = mem[addr];

endmodule