// ============================================================
// tb/uvm/mem_scoreboard.sv  -  Reference model + checker.
// - Maintains a shadow memory updated on every observed write.
// - On every observed read, compares dout against shadow.
// - Counts pass/fail and prints PASS/FAIL lines parseable by
//   tools/regression.py (regex looks for the keywords PASS/FAIL).
// ============================================================

class mem_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(mem_scoreboard)

    uvm_analysis_imp #(mem_seq_item, mem_scoreboard) item_collected_export;

    bit [7:0] shadow_mem [0:7];
    int       total_checks;
    int       pass_count;
    int       fail_count;
    int       read_index;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        int k;
        item_collected_export = new("item_collected_export", this);
        for (k = 0; k < 8; k = k + 1) shadow_mem[k] = 8'h00;
    endfunction

    // Called for every transaction the monitor publishes
    function void write(mem_seq_item t);
        if (t.we) begin
            shadow_mem[t.addr] = t.din;
            `uvm_info("SB",
                $sformatf("write addr=%0d din=0x%02h -> shadow updated",
                          t.addr, t.din), UVM_HIGH)
        end
        else begin
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

    function void report_phase(uvm_phase phase);
        `uvm_info("SB",
            $sformatf("SCOREBOARD_SUMMARY total=%0d pass=%0d fail=%0d",
                      total_checks, pass_count, fail_count), UVM_NONE)
    endfunction
endclass