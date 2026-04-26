# ============================================================
# scripts/run_uvm_bug.tcl  -  Buggy UVM run (intentional FAIL).
#   vsim -c -do scripts/run_uvm_bug.tcl
# ============================================================

if {[file isdirectory work]} { vdel -lib work -all }
vlib work

# +define+USE_BUGGY_DUT swaps in memory_ctrl_buggy inside tb_top_uvm
vlog -sv +incdir+tb/uvm +define+USE_BUGGY_DUT \
        rtl/memory_ctrl.sv \
        rtl/memory_ctrl_buggy.sv \
        tb/uvm/mem_if.sv \
        tb/uvm/mem_uvm_pkg.sv \
        tb/uvm/tb_top_uvm.sv

if {![file isdirectory reports]} { file mkdir reports }
transcript file reports/uvm_bug_log.txt

vsim -t 1ns -L mtiUvm work.tb_top_uvm \
     +UVM_TESTNAME=mem_base_test \
     +UVM_VERBOSITY=UVM_LOW \
     +UVM_MAX_QUIT_COUNT=999

run -all
quit -f