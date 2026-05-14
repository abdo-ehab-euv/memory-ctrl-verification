// ============================================================
// tb/uvm/mem_sequence.sv — Stimulus Sequences
// ------------------------------------------------------------
// Three sequences providing different stimulus strategies:
//   1. mem_directed_seq   — Directed corner-case tests (T1–T3)
//                           plus boundary-value sweeps.
//   2. mem_random_seq     — Constrained-random traffic with
//                           configurable transaction count.
//   3. mem_sequential_seq — Ascending address pattern for
//                           address-transition coverage.
// ============================================================


// ==========================================================
// Directed sequence — corner-case and boundary tests
// ==========================================================
class mem_directed_seq extends uvm_sequence #(mem_seq_item);
    `uvm_object_utils(mem_directed_seq)

    function new(string name = "mem_directed_seq");
        super.new(name);
    endfunction

    task body();
        mem_seq_item req;
        int i;

        // T1: Write 0xFF to address 0, read back — basic sanity
        `uvm_do_with(req, { req.we == 1; req.addr == 0; req.din == 8'hFF; })
        `uvm_do_with(req, { req.we == 0; req.addr == 0; })

        // T2: Write all 8 addresses with distinct data, read all back
        for (i = 0; i < 8; i++)
            `uvm_do_with(req, { req.we == 1; req.addr == i; req.din == (8'hA0 + i); })
        for (i = 0; i < 8; i++)
            `uvm_do_with(req, { req.we == 0; req.addr == i; })

        // T3: Triple overwrite of addr 3, read back — latest-value check
        `uvm_do_with(req, { req.we == 1; req.addr == 3; req.din == 8'h11; })
        `uvm_do_with(req, { req.we == 1; req.addr == 3; req.din == 8'h22; })
        `uvm_do_with(req, { req.we == 1; req.addr == 3; req.din == 8'h33; })
        `uvm_do_with(req, { req.we == 0; req.addr == 3; })

        // Boundary data values: 0x00 and 0xFF on every address
        for (i = 0; i < 8; i++) begin
            `uvm_do_with(req, { req.we == 1; req.addr == i; req.din == 8'h00; })
            `uvm_do_with(req, { req.we == 0; req.addr == i; })
        end
        for (i = 0; i < 8; i++) begin
            `uvm_do_with(req, { req.we == 1; req.addr == i; req.din == 8'hFF; })
            `uvm_do_with(req, { req.we == 0; req.addr == i; })
        end
    endtask

endclass


// ==========================================================
// Random sequence — constrained-random traffic
// ==========================================================
class mem_random_seq extends uvm_sequence #(mem_seq_item);
    `uvm_object_utils(mem_random_seq)

    rand int unsigned n_trans = 100;
    constraint c_n { n_trans inside {[100:200]}; }

    function new(string name = "mem_random_seq");
        super.new(name);
    endfunction

    task body();
        mem_seq_item req;
        repeat (n_trans)
            `uvm_do(req)
    endtask

endclass


// ==========================================================
// Sequential-pattern sequence — ascending address sweep
// ==========================================================
class mem_sequential_seq extends uvm_sequence #(mem_seq_item);
    `uvm_object_utils(mem_sequential_seq)

    function new(string name = "mem_sequential_seq");
        super.new(name);
    endfunction

    task body();
        mem_seq_item req;
        int i;

        // Ascending writes: address 0 → 7
        for (i = 0; i < 8; i++)
            `uvm_do_with(req, { req.we == 1; req.addr == i; req.din == (8'h10 + i); })

        // Ascending reads: address 0 → 7
        for (i = 0; i < 8; i++)
            `uvm_do_with(req, { req.we == 0; req.addr == i; })
    endtask

endclass