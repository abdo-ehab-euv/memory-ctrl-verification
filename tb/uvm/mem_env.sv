// ============================================================
// tb/uvm/mem_env.sv — Top-Level UVM Environment
// ------------------------------------------------------------
// Instantiates the agent, scoreboard, and coverage subscriber.
// Connects the monitor's analysis port to both the scoreboard
// and coverage so every observed transaction is automatically
// checked and coverage-sampled.
// ============================================================

class mem_env extends uvm_env;
    `uvm_component_utils(mem_env)

    mem_agent      agent;
    mem_scoreboard sb;
    mem_coverage   cov;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        agent = mem_agent     ::type_id::create("agent", this);
        sb    = mem_scoreboard::type_id::create("sb",    this);
        cov   = mem_coverage  ::type_id::create("cov",   this);
    endfunction

    // Wire the monitor's analysis port to scoreboard + coverage
    function void connect_phase(uvm_phase phase);
        agent.monitor.ap.connect(sb.item_collected_export);
        agent.monitor.ap.connect(cov.analysis_export);
    endfunction

endclass