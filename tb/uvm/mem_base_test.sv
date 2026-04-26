// ============================================================
// tb/uvm/mem_base_test.sv  -  Default test: directed then random.
// ============================================================

class mem_base_test extends uvm_test;
    `uvm_component_utils(mem_base_test)

    mem_env env;

    function new(string name, uvm_component parent); super.new(name, parent); endfunction

    function void build_phase(uvm_phase phase);
        env = mem_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        mem_directed_seq   dseq;
        mem_sequential_seq sseq;
        mem_random_seq     rseq;

        phase.raise_objection(this);

        `uvm_info("TEST", "=== Starting directed sequence ===", UVM_LOW)
        dseq = mem_directed_seq::type_id::create("dseq");
        dseq.start(env.agent.sequencer);

        `uvm_info("TEST", "=== Starting sequential sub-sequence ===", UVM_LOW)
        sseq = mem_sequential_seq::type_id::create("sseq");
        sseq.start(env.agent.sequencer);

        `uvm_info("TEST", "=== Starting random sequence (>=100 transactions) ===", UVM_LOW)
        rseq = mem_random_seq::type_id::create("rseq");
        if (!rseq.randomize() with { n_trans == 120; })
            `uvm_fatal("TEST", "rseq randomize failed")
        rseq.start(env.agent.sequencer);

        #500;
        phase.drop_objection(this);
    endtask

    function void report_phase(uvm_phase phase);
        `uvm_info("TEST", "=== mem_base_test complete ===", UVM_NONE)
    endfunction
endclass