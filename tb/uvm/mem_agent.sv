// ============================================================
// tb/uvm/mem_agent.sv  -  Bundles sequencer, driver, monitor.
// ============================================================

typedef uvm_sequencer #(mem_seq_item) mem_sequencer;

class mem_agent extends uvm_agent;
    `uvm_component_utils(mem_agent)

    mem_sequencer sequencer;
    mem_driver    driver;
    mem_monitor   monitor;

    function new(string name, uvm_component parent); super.new(name, parent); endfunction

    function void build_phase(uvm_phase phase);
        sequencer = mem_sequencer::type_id::create("sequencer", this);
        driver    = mem_driver   ::type_id::create("driver",    this);
        monitor   = mem_monitor  ::type_id::create("monitor",   this);
    endfunction

    function void connect_phase(uvm_phase phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
endclass