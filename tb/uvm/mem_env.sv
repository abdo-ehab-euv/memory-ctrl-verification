// ============================================================
// tb/uvm/mem_env.sv  -  Top of the verification environment.
// Wires the agent's monitor to scoreboard + coverage.
// ============================================================

class mem_env extends uvm_env;
    `uvm_component_utils(mem_env)

    mem_agent      agent;
    mem_scoreboard sb;
    mem_coverage   cov;

    function new(string name, uvm_component parent); super.new(name, parent); endfunction

    function void build_phase(uvm_phase phase);
        agent = mem_agent     ::type_id::create("agent", this);
        sb    = mem_scoreboard::type_id::create("sb",    this);
        cov   = mem_coverage  ::type_id::create("cov",   this);
    endfunction

    function void connect_phase(uvm_phase phase);
        agent.monitor.ap.connect(sb.item_collected_export);
        agent.monitor.ap.connect(cov.analysis_export);
    endfunction
endclass