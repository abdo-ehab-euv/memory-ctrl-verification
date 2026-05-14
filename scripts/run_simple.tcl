# ============================================================
# scripts/run_simple.tcl — Simple Flow (No UVM)
# ------------------------------------------------------------
# Usage:  vsim -c -do scripts/run_simple.tcl
#
# Runs the task-based testbench (tb_top + mem_test.sv).
# Works with both Questa and free ModelSim Intel Starter.
# ============================================================

# Clean previous work library
if {[file isdirectory work]} { vdel -lib work -all }
vlib work

# Compile: +incdir so `include "mem_test.sv" resolves
vlog -sv +incdir+tb/simple \
        rtl/memory_ctrl.sv \
        tb/simple/tb_top.sv

# Create reports directory and redirect transcript
if {![file isdirectory reports]} { file mkdir reports }
transcript file reports/simple_sim_log.txt

# Elaborate and run
vsim -t 1ns work.tb_top
run -all
quit -f