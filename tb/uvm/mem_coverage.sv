// ============================================================
// tb/uvm/mem_coverage.sv — Functional Coverage Subscriber
// ------------------------------------------------------------
// Collects functional coverage metrics to measure verification
// completeness against the verification plan.
//
// Coverage model:
//
// cg_mem (main covergroup):
//   cp_addr      — one bin per address (0–7), ensures all
//                  locations are exercised.
//   cp_op        — write_op / read_op, ensures both operations
//                  are tested.
//   cp_data      — classifies din into zero, all_ones, low_mid,
//                  high_mid to verify boundary and mid-range data.
//   cross_addr_op — cross of cp_addr × cp_op (16 bins), ensures
//                   every address is both read and written.
//
// cg_addr_trans (address transition covergroup):
//   cp_trans     — same_addr / diff_addr bins track whether
//                  consecutive transactions target the same or
//                  different addresses (back-to-back scenarios).
//
// Reporting:
//   report_phase prints a COVERAGE_REPORT line with per-coverpoint
//   percentages. This line is parsed by dashboard.py to render
//   coverage bars in the HTML dashboard.
//
// NOTE: This is functional coverage (specification-driven).
//       Code coverage (line/toggle/FSM) requires simulator
//       flags and is not collected here.
// ============================================================

class mem_coverage extends uvm_subscriber #(mem_seq_item);
    `uvm_component_utils(mem_coverage)

    mem_seq_item current;
    bit [2:0]    prev_addr = 0;
    bit          have_prev = 0;

    // ----------------------------------------------------------
    // Covergroup: main DUT feature coverage
    // ----------------------------------------------------------
    covergroup cg_mem;
        option.per_instance = 1;

        // Address coverage — one bin per location
        cp_addr : coverpoint current.addr {
            bins addr_bin[] = {[0:7]};
        }

        // Operation coverage — read vs. write
        cp_op : coverpoint current.we {
            bins write_op = {1};
            bins read_op  = {0};
        }

        // Data classification coverage
        cp_data : coverpoint current.din {
            bins zero      = {8'h00};
            bins all_ones  = {8'hFF};
            bins low_mid   = {[8'h01 : 8'h7F]};
            bins high_mid  = {[8'h80 : 8'hFE]};
        }

        // Cross: every address must be both read and written
        cross_addr_op : cross cp_addr, cp_op;
    endgroup

    // ----------------------------------------------------------
    // Covergroup: address transition coverage
    // ----------------------------------------------------------
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

    // ----------------------------------------------------------
    // write() — called for each transaction from the monitor
    // ----------------------------------------------------------
    function void write(mem_seq_item t);
        current = t;
        cg_mem.sample();

        if (have_prev)
            cg_addr_trans.sample(prev_addr, t.addr);

        prev_addr = t.addr;
        have_prev = 1;
    endfunction

    // ----------------------------------------------------------
    // report_phase — print coverage summary for dashboard parser
    // ----------------------------------------------------------
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