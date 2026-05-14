// ============================================================
// tb/uvm/mem_monitor.sv — UVM Monitor
// ------------------------------------------------------------
// Passively observes the DUT interface and broadcasts completed
// transactions to the scoreboard and coverage subscriber via
// an analysis port.
//
// Sampling strategy:
//   - Sample at posedge clk + 1ns delta delay.
//   - The 1ns delay lets the DUT's combinational read (dout)
//     settle after the clock edge before we capture it.
//   - Only emit a transaction when tb_valid == 1 AND rst_n == 1,
//     so idle cycles and reset cycles are filtered out.
// ============================================================

class mem_monitor extends uvm_monitor;
    `uvm_component_utils(mem_monitor)

    virtual mem_if vif;

    // Analysis port — broadcasts to scoreboard + coverage
    uvm_analysis_port #(mem_seq_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    // Retrieve the virtual interface handle from config_db
    function void build_phase(uvm_phase phase);
        if (!uvm_config_db#(virtual mem_if)::get(this, "", "vif", vif))
            `uvm_fatal("MON", "virtual interface not set in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        mem_seq_item t;

        forever begin
            @(posedge vif.clk);
            #1;   // 1ns delta — let combinational read (dout) settle

            // Only sample when out of reset AND driver signals valid data
            if (vif.rst_n && vif.tb_valid) begin
                t = mem_seq_item::type_id::create("t");
                t.we   = vif.we;
                t.addr = vif.addr;
                t.din  = vif.din;
                t.dout = vif.dout;   // captured after combinational settle
                ap.write(t);         // broadcast to scoreboard + coverage
            end
        end
    endtask

endclass