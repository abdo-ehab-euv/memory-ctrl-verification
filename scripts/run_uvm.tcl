# ============================================================
# scripts/run_uvm.tcl — Clean UVM Regression (Questa)
# ------------------------------------------------------------
# Usage:  vsim -c -do scripts/run_uvm.tcl
#
# Notes:
#   * Questa auto-imports uvm_pkg via -L mtiUvm.
#   * Free Intel ModelSim Starter does NOT support UVM.
#   * Uses the clean DUT (memory_ctrl.sv) — no bugs.
# ============================================================

# Clean previous work library
if {[file isdirectory work]} { vdel -lib work -all }
vlib work

# Compile order: RTL -> interface -> UVM package -> top
vlog -sv +incdir+tb/uvm \
        rtl/memory_ctrl.sv \
        tb/uvm/mem_if.sv \
        tb/uvm/mem_uvm_pkg.sv \
        tb/uvm/tb_top_uvm.sv

# Create reports directory and redirect transcript
if {![file isdirectory reports]} { file mkdir reports }
transcript file reports/uvm_sim_log.txt

# Elaborate and run
vsim -t 1ns -L mtiUvm work.tb_top_uvm \
     +UVM_TESTNAME=mem_base_test \
     +UVM_VERBOSITY=UVM_LOW

run -all
quit -f