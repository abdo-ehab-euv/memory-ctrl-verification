// ============================================================
// tb/uvm/mem_base_test.sv — Default UVM Test
// ------------------------------------------------------------
// Launches three sequences in order:
//   1. mem_directed_seq   — corner-case and boundary tests
//   2. mem_sequential_seq — ascending address pattern
//   3. mem_random_seq     — 120 constrained-random transactions
//
// Objection management:
//   raise_objection() at the start prevents the UVM phasing
//   mechanism from ending the test prematurely. drop_objection()
//   after a 500ns drain time signals the test is complete.
// ============================================================

class mem_base_test extends uvm_test;
    `uvm_component_utils(mem_base_test)

    mem_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        env = mem_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        mem_directed_seq   dseq;
        mem_sequential_seq sseq;
        mem_random_seq     rseq;

        phase.raise_objection(this);

        // Phase 1: Directed corner-case tests
        `uvm_info("TEST", "=== Starting directed sequence ===", UVM_LOW)
        dseq = mem_directed_seq::type_id::create("dseq");
        dseq.start(env.agent.sequencer);

        // Phase 2: Sequential address pattern
        `uvm_info("TEST", "=== Starting sequential sub-sequence ===", UVM_LOW)
        sseq = mem_sequential_seq::type_id::create("sseq");
        sseq.start(env.agent.sequencer);

        // Phase 3: Constrained-random traffic (120 transactions)
        `uvm_info("TEST", "=== Starting random sequence (>=100 transactions) ===", UVM_LOW)
        rseq = mem_random_seq::type_id::create("rseq");
        if (!rseq.randomize() with { n_trans == 120; })
            `uvm_fatal("TEST", "rseq randomize failed")
        rseq.start(env.agent.sequencer);

        // Drain time — allow final transactions to propagate
        #500;
        phase.drop_objection(this);
    endtask

    function void report_phase(uvm_phase phase);
        `uvm_info("TEST", "=== mem_base_test complete ===", UVM_NONE)
    endfunction

endclass