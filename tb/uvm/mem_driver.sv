// ============================================================
// tb/uvm/mem_driver.sv  -  Drives transactions onto mem_if.
// Sets tb_valid for one cycle per transaction so the monitor
// only emits "real" transactions to the scoreboard.
// ============================================================

class mem_driver extends uvm_driver #(mem_seq_item);
    `uvm_component_utils(mem_driver)

    virtual mem_if vif;

    function new(string name, uvm_component parent); super.new(name, parent); endfunction

    function void build_phase(uvm_phase phase);
        if (!uvm_config_db#(virtual mem_if)::get(this, "", "vif", vif))
            `uvm_fatal("DRV", "virtual interface not set in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        // Idle defaults
        vif.we       = 0;
        vif.addr     = 0;
        vif.din      = 0;
        vif.tb_valid = 0;

        // Wait until reset releases
        @(posedge vif.rst_n);
        @(posedge vif.clk);

        forever begin
            seq_item_port.get_next_item(req);
            drive_one(req);
            seq_item_port.item_done();
        end
    endtask

    task drive_one(mem_seq_item t);
        @(negedge vif.clk);
        vif.we       = t.we;
        vif.addr     = t.addr;
        vif.din      = t.din;
        vif.tb_valid = 1;
        @(posedge vif.clk);
        @(negedge vif.clk);
        vif.we       = 0;
        vif.tb_valid = 0;
    endtask
endclass