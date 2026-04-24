# ============================================================
# run_sim.tcl  -  Clean (bug-free) run
# Usage: vsim -c -do run_sim.tcl
# ============================================================

# 1. Remove any stale work library
if {[file isdirectory work]} {
    vdel -lib work -all
}

# 2. Fresh work library
vlib work

# 3. Compile RTL + TB (mem_test.sv is `included inside tb_top)
vlog -sv memory_ctrl.sv tb_top.sv

# 4. Redirect transcript to sim_log.txt (consumed by regression.py)
transcript file sim_log.txt

# 5. Elaborate + load top
vsim -t 1ns work.tb_top

# 6. Run until $finish
run -all

# 7. Exit ModelSim
quit -f