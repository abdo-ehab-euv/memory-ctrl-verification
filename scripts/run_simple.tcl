# ============================================================
# scripts/run_simple.tcl
# Original simple flow. Run from repo root:
#   vsim -c -do scripts/run_simple.tcl
# ============================================================

if {[file isdirectory work]} { vdel -lib work -all }
vlib work

# +incdir so `include "mem_test.sv" resolves
vlog -sv +incdir+tb/simple rtl/memory_ctrl.sv tb/simple/tb_top.sv

if {![file isdirectory reports]} { file mkdir reports }
transcript file reports/simple_sim_log.txt

vsim -t 1ns work.tb_top
run -all
quit -f