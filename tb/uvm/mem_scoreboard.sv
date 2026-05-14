// ============================================================
// tb/uvm/mem_scoreboard.sv — Self-Checking Scoreboard
// ------------------------------------------------------------
// Central verification checker using a shadow-memory reference
// model to automatically validate every DUT read.
//
// Reference model:
//   shadow_mem[0:7] — mirrors the expected state of the DUT's
//   internal memory. Initialized to all-zeros (matching reset).
//
// Operation:
//   - On WRITE (we==1): update shadow_mem[addr] = din.
//     No comparison is needed; we trust the driver sent it.
//   - On READ  (we==0): compare DUT's dout against
//     shadow_mem[addr]. Report PASS or FAIL with expected/actual.
//
// Output format:
//   PASS/FAIL lines are regex-friendly so that tools/regression.py
//   and tools/dashboard.py can parse results automatically.
//
// Design decisions:
//   - Mismatches use `uvm_error` (not `uvm_fatal`) so the
//     simulation continues and ALL failures are collected.
//   - Each read check has a unique name (read_chk<N>_addr<A>)
//     for log traceability and per-check debugging.
//   - pass_count / fail_count are summarized in report_phase
//     as SCOREBOARD_SUMMARY for the regression parser.
// ============================================================

class mem_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(mem_scoreboard)

    // Analysis import — receives transactions from the monitor
    uvm_analysis_imp #(mem_seq_item, mem_scoreboard) item_collected_export;

    // Shadow memory — transaction-level reference model
    bit [7:0] shadow_mem [0:7];

    // Scoreboard statistics
    int total_checks;
    int pass_count;
    int fail_count;
    int read_index;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        int k;
        item_collected_export = new("item_collected_export", this);

        // Initialize shadow to match DUT post-reset state
        for (k = 0; k < 8; k = k + 1)
            shadow_mem[k] = 8'h00;
    endfunction

    // ----------------------------------------------------------
    // write() — called automatically for every transaction the
    //           monitor publishes on its analysis port.
    // ----------------------------------------------------------
    function void write(mem_seq_item t);
        if (t.we) begin
            // WRITE transaction: update the reference model
            shadow_mem[t.addr] = t.din;
            `uvm_info("SB",
                $sformatf("write addr=%0d din=0x%02h -> shadow updated",
                          t.addr, t.din), UVM_HIGH)
        end
        else begin
            // READ transaction: compare DUT output vs. expected
            string tname;
            total_checks++;
            read_index++;
            tname = $sformatf("read_chk%0d_addr%0d", read_index, t.addr);

            if (t.dout === shadow_mem[t.addr]) begin
                pass_count++;
                `uvm_info("SB",
                    $sformatf("PASS %s expected=0x%02h actual=0x%02h",
                              tname, shadow_mem[t.addr], t.dout), UVM_LOW)
            end
            else begin
                fail_count++;
                `uvm_error("SB",
                    $sformatf("FAIL %s expected=0x%02h actual=0x%02h",
                              tname, shadow_mem[t.addr], t.dout))
            end
        end
    endfunction

    // ----------------------------------------------------------
    // report_phase — final summary for regression parser
    // ----------------------------------------------------------
    function void report_phase(uvm_phase phase);
        `uvm_info("SB",
            $sformatf("SCOREBOARD_SUMMARY total=%0d pass=%0d fail=%0d",
                      total_checks, pass_count, fail_count), UVM_NONE)
    endfunction

endclass