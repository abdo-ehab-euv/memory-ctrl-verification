// ============================================================
// tb/uvm/mem_coverage.sv  -  Functional coverage subscriber.
// Covergroups for: address, operation, data classes, and
// previous-current address transitions. Final summary printed
// in a regex-friendly form for the dashboard.
// ============================================================

class mem_coverage extends uvm_subscriber #(mem_seq_item);
    `uvm_component_utils(mem_coverage)

    mem_seq_item current;
    bit [2:0]    prev_addr = 0;
    bit          have_prev = 0;

    covergroup cg_mem;
        option.per_instance = 1;

        cp_addr : coverpoint current.addr {
            bins addr_bin[] = {[0:7]};
        }
        cp_op   : coverpoint current.we {
            bins write_op = {1};
            bins read_op  = {0};
        }
        cp_data : coverpoint current.din {
            bins zero      = {8'h00};
            bins all_ones  = {8'hFF};
            bins low_mid   = {[8'h01 : 8'h7F]};
            bins high_mid  = {[8'h80 : 8'hFE]};
        }
        cross_addr_op : cross cp_addr, cp_op;
    endgroup

    covergroup cg_addr_trans with function sample(bit [2:0] p, bit [2:0] c);
        option.per_instance = 1;
        cp_trans : coverpoint c {
            bins same_addr = {[0:7]} iff (p == c);
            bins diff_addr = {[0:7]} iff (p != c);
        }
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg_mem        = new();
        cg_addr_trans = new();
    endfunction

    function void write(mem_seq_item t);
        current = t;
        cg_mem.sample();
        if (have_prev) cg_addr_trans.sample(prev_addr, t.addr);
        prev_addr = t.addr;
        have_prev = 1;
    endfunction

    function void report_phase(uvm_phase phase);
        real ca, co, cd, cx, ct, overall;
        ca = cg_mem.cp_addr.get_inst_coverage();
        co = cg_mem.cp_op.get_inst_coverage();
        cd = cg_mem.cp_data.get_inst_coverage();
        cx = cg_mem.cross_addr_op.get_inst_coverage();
        ct = cg_addr_trans.cp_trans.get_inst_coverage();
        overall = (ca + co + cd + cx + ct) / 5.0;

        `uvm_info("COV",
            $sformatf("COVERAGE_REPORT addr=%0.1f%% op=%0.1f%% data=%0.1f%% cross=%0.1f%% trans=%0.1f%% overall=%0.1f%%",
                      ca, co, cd, cx, ct, overall), UVM_NONE)
    endfunction
endclass