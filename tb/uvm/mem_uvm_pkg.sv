// ============================================================
// tb/uvm/mem_uvm_pkg.sv  -  UVM package wrapper.
// Includes ALL UVM component files in dependency order. Only
// this file is compiled by vlog; the others are pulled in via
// `include. Make sure +incdir+tb/uvm is on the vlog command.
// ============================================================
`timescale 1ns/1ps

package mem_uvm_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "mem_seq_item.sv"
    `include "mem_sequence.sv"
    `include "mem_driver.sv"
    `include "mem_monitor.sv"
    `include "mem_scoreboard.sv"
    `include "mem_coverage.sv"
    `include "mem_agent.sv"
    `include "mem_env.sv"
    `include "mem_base_test.sv"
endpackage