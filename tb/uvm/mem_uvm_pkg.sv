// ============================================================
// tb/uvm/mem_uvm_pkg.sv — UVM Package Wrapper
// ------------------------------------------------------------
// Includes ALL UVM component files in dependency order.
// Only this file is compiled by vlog; the others are pulled
// in via `include. Requires +incdir+tb/uvm on the vlog command.
//
// Compile order:
//   1. mem_seq_item   — transaction (no dependencies)
//   2. mem_sequence   — sequences (depends on seq_item)
//   3. mem_driver     — drives transactions (depends on seq_item)
//   4. mem_monitor    — observes DUT (depends on seq_item)
//   5. mem_scoreboard — checker (depends on seq_item)
//   6. mem_coverage   — coverage (depends on seq_item)
//   7. mem_agent      — bundles sequencer/driver/monitor
//   8. mem_env        — top environment
//   9. mem_base_test  — default test (depends on env + sequences)
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