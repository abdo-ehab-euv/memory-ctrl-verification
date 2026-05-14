# =============================================================
# Makefile — SRAM Controller UVM Verification
# =============================================================
# Convenience targets wrapping the existing TCL / Python scripts.
# Requires: Questa (for UVM) or ModelSim Intel Starter (simple).
#           Python 3.x with tabulate (pip install -r requirements.txt)
# =============================================================

.PHONY: simple uvm bug dashboard clean help

help: ## Show available targets
	@echo ""
	@echo "  make simple      Run simple (non-UVM) testbench"
	@echo "  make uvm         Run UVM clean regression"
	@echo "  make bug         Run UVM bug-injection regression"
	@echo "  make dashboard   Generate HTML dashboard from logs"
	@echo "  make clean       Remove simulation artifacts"
	@echo ""

simple: ## Simple testbench — no UVM required
	vsim -c -do scripts/run_simple.tcl
	python tools/regression.py reports/simple_sim_log.txt

uvm: ## UVM clean regression (Questa required)
	vsim -c -do scripts/run_uvm.tcl
	python tools/regression.py reports/uvm_sim_log.txt

bug: ## UVM bug-injection regression
	vsim -c -do scripts/run_uvm_bug.tcl
	python tools/regression.py reports/uvm_bug_log.txt

dashboard: ## Generate HTML dashboard from available logs
	python tools/dashboard.py reports/uvm_sim_log.txt reports/uvm_bug_log.txt

clean: ## Remove simulation artifacts
	powershell -ExecutionPolicy Bypass -File scripts/clean.ps1
