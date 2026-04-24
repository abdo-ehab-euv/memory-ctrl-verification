# ============================================================
# run_bug_sim.tcl  -  INTENTIONAL BUG build for debug practice
# Usage: vsim -c -do run_bug_sim.tcl
#
# Compiles memory_ctrl.sv with +define+INJECT_BUG so the DUT
# mis-routes writes for addr==5. regression.py should detect
# failures automatically.
# ============================================================

if {[file isdirectory work]} {
    vdel -lib work -all
}

vlib work

vlog -sv +define+INJECT_BUG memory_ctrl.sv tb_top.sv

transcript file sim_log.txt

vsim -t 1ns work.tb_top

run -all

quit -f