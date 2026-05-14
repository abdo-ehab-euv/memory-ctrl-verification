// ============================================================
// tb/uvm/mem_seq_item.sv — Transaction Class
// ------------------------------------------------------------
// Defines the sequence item (transaction) exchanged between
// the sequencer, driver, monitor, scoreboard, and coverage.
//
// Fields:
//   we   — write enable (1 = write, 0 = read)
//   addr — 3-bit address selecting one of 8 memory locations
//   din  — 8-bit data to write (stimulus, randomized)
//   dout — 8-bit data read back (observed by monitor, not rand)
// ============================================================

class mem_seq_item extends uvm_sequence_item;

    rand bit       we;
    rand bit [2:0] addr;
    rand bit [7:0] din;
    bit      [7:0] dout;          // populated by monitor, not randomized

    constraint c_addr { addr inside {[0:7]};   }
    constraint c_din  { din  inside {[0:255]}; }

    `uvm_object_utils_begin(mem_seq_item)
        `uvm_field_int(we,   UVM_ALL_ON)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(din,  UVM_ALL_ON)
        `uvm_field_int(dout, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "mem_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("we=%0b addr=%0d din=0x%02h dout=0x%02h",
                         we, addr, din, dout);
    endfunction

endclass