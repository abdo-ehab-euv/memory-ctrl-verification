// ============================================================
// tb/uvm/mem_monitor.sv  -  Observes mem_if and broadcasts
// completed transactions via an analysis port. Only emits
// when tb_valid is asserted (a "real" transaction cycle).
// ============================================================

class mem_monitor extends uvm_monitor;
    `uvm_component_utils(mem_monitor)

    virtual mem_if vif;
    uvm_analysis_port #(mem_seq_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        if (!uvm_config_db#(virtual mem_if)::get(this, "", "vif", vif))
            `uvm_fatal("MON", "virtual interface not set in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        mem_seq_item t;
        forever begin
            @(posedge vif.clk);
            #1;   // let combinational read settle
            if (vif.rst_n && vif.tb_valid) begin
                t = mem_seq_item::type_id::create("t");
                t.we   = vif.we;
                t.addr = vif.addr;
                t.din  = vif.din;
                t.dout = vif.dout;
                ap.write(t);
            end
        end
    endtask
endclass