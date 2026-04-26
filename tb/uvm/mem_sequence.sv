// ============================================================
// tb/uvm/mem_sequence.sv  -  Directed + random sequences.
// ============================================================

// ---------- Directed sequence ----------
class mem_directed_seq extends uvm_sequence #(mem_seq_item);
    `uvm_object_utils(mem_directed_seq)

    function new(string name = "mem_directed_seq"); super.new(name); endfunction

    task body();
        mem_seq_item req;
        int i;

        // T1: write 0xFF to addr 0 then read it back
        `uvm_do_with(req, { req.we == 1; req.addr == 0; req.din == 8'hFF; })
        `uvm_do_with(req, { req.we == 0; req.addr == 0; })

        // T2: write all 8 addresses with distinct data, then read all back
        for (i = 0; i < 8; i++)
            `uvm_do_with(req, { req.we == 1; req.addr == i; req.din == (8'hA0 + i); })
        for (i = 0; i < 8; i++)
            `uvm_do_with(req, { req.we == 0; req.addr == i; })

        // T3: triple overwrite of addr 3 then read
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

// ---------- Random sequence ----------
class mem_random_seq extends uvm_sequence #(mem_seq_item);
    `uvm_object_utils(mem_random_seq)

    rand int unsigned n_trans = 100;
    constraint c_n { n_trans inside {[100:200]}; }

    function new(string name = "mem_random_seq"); super.new(name); endfunction

    task body();
        mem_seq_item req;
        repeat (n_trans) `uvm_do(req)
    endtask
endclass

// ---------- Sequential-pattern sub-sequence (writes ascending) ----------
class mem_sequential_seq extends uvm_sequence #(mem_seq_item);
    `uvm_object_utils(mem_sequential_seq)

    function new(string name = "mem_sequential_seq"); super.new(name); endfunction

    task body();
        mem_seq_item req;
        int i;
        for (i = 0; i < 8; i++)
            `uvm_do_with(req, { req.we == 1; req.addr == i; req.din == (8'h10 + i); })
        for (i = 0; i < 8; i++)
            `uvm_do_with(req, { req.we == 0; req.addr == i; })
    endtask
endclass