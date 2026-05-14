// ============================================================
// tb/uvm/mem_driver.sv — UVM Driver
// ------------------------------------------------------------
// Drives DUT stimulus onto mem_if from sequence items.
//
// Timing protocol:
//   1. Wait for reset release (posedge rst_n).
//   2. For each transaction from the sequencer:
//      a. Set we/addr/din at negedge clk (setup time).
//      b. Assert tb_valid = 1 for exactly one clock cycle
//         so the monitor knows this is a real transaction.
//      c. After posedge clk (DUT samples), deassert we and
//         tb_valid at the next negedge.
//
// The tb_valid signal is a testbench-only handshake — it does
// NOT exist in the real DUT. It prevents the monitor from
// sampling idle bus cycles as spurious transactions.
// ============================================================

class mem_driver extends uvm_driver #(mem_seq_item);
    `uvm_component_utils(mem_driver)

    virtual mem_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // Retrieve the virtual interface handle from config_db
    function void build_phase(uvm_phase phase);
        if (!uvm_config_db#(virtual mem_if)::get(this, "", "vif", vif))
            `uvm_fatal("DRV", "virtual interface not set in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        // Drive idle defaults before reset completes
        vif.we       = 0;
        vif.addr     = 0;
        vif.din      = 0;
        vif.tb_valid = 0;

        // Wait for DUT to exit reset
        @(posedge vif.rst_n);
        @(posedge vif.clk);

        // Main driver loop — pops items from the sequencer
        forever begin
            seq_item_port.get_next_item(req);
            drive_one(req);
            seq_item_port.item_done();
        end
    endtask

    // Drive a single transaction onto the interface
    task drive_one(mem_seq_item t);
        // Setup stimulus at negedge (before next posedge sample)
        @(negedge vif.clk);
        vif.we       = t.we;
        vif.addr     = t.addr;
        vif.din      = t.din;
        vif.tb_valid = 1;           // mark this cycle as a valid transaction

        // DUT samples on posedge clk
        @(posedge vif.clk);

        // Deassert after one cycle — return bus to idle
        @(negedge vif.clk);
        vif.we       = 0;
        vif.tb_valid = 0;
    endtask

endclass