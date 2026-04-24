// ============================================================
// mem_test.sv
// SystemVerilog task library - INCLUDED inside tb_top.
// Provides helper tasks + directed tests (T1..T5) +
// constrained-random test (50 ops) with shadow-memory checking.
//
// IMPORTANT: This file is `included, NOT separately compiled.
// Do NOT add `timescale or module headers here.
// ============================================================

// --------- Reporting helpers ---------
task automatic print_pass(input string test_name);
    $display("PASS %0s", test_name);
    pass_count = pass_count + 1;
endtask

task automatic print_fail(input string       test_name,
                          input logic [7:0]  expected,
                          input logic [7:0]  actual);
    $display("FAIL %0s expected=0x%02X actual=0x%02X",
             test_name, expected, actual);
    fail_count = fail_count + 1;
endtask

// --------- Driver helpers ---------
// Drive one write transaction and update the shadow memory.
task automatic write_mem(input logic [2:0] a, input logic [7:0] d);
    @(negedge clk);
    we   = 1'b1;
    addr = a;
    din  = d;
    @(posedge clk);           // Write samples here
    @(negedge clk);
    we            = 1'b0;
    shadow_mem[a] = d;        // Keep shadow in sync
endtask

// Drive a read, compare against an expected value and report.
task automatic read_check(input logic [2:0] a,
                          input logic [7:0] expected,
                          input string      test_name);
    @(negedge clk);
    we   = 1'b0;
    addr = a;
    #1;                       // let combinational read settle
    if (dout === expected)
        print_pass(test_name);
    else
        print_fail(test_name, expected, dout);
endtask

// Apply a clean in-test reset and also wipe the shadow
task automatic apply_reset();
    int k;
    @(negedge clk);
    rst_n = 1'b0;
    repeat (3) @(posedge clk);
    @(negedge clk);
    rst_n = 1'b1;
    @(posedge clk);
    for (k = 0; k < 8; k = k + 1) shadow_mem[k] = 8'h00;
endtask

// ============================================================
// Directed tests
// ============================================================

// T1: write 0xFF to addr 0 and read it back
task automatic test_T1_basic();
    write_mem(3'd0, 8'hFF);
    read_check(3'd0, 8'hFF, "T1_basic_write_read");
endtask

// T2: write all 8 addresses with distinct data, read each back
task automatic test_T2_all_addresses();
    logic [7:0] data_arr [0:7];
    string      tname;
    int         i;

    data_arr[0] = 8'hA0;
    data_arr[1] = 8'hB1;
    data_arr[2] = 8'hC2;
    data_arr[3] = 8'hD3;
    data_arr[4] = 8'hE4;
    data_arr[5] = 8'hF5;
    data_arr[6] = 8'h16;
    data_arr[7] = 8'h27;

    for (i = 0; i < 8; i = i + 1)
        write_mem(i[2:0], data_arr[i]);

    for (i = 0; i < 8; i = i + 1) begin
        tname = $sformatf("T2_all_addresses_addr%0d", i);
        read_check(i[2:0], data_arr[i], tname);
    end
endtask

// T3: overwrite the same address and confirm latest value
task automatic test_T3_overwrite();
    write_mem(3'd3, 8'h11);
    write_mem(3'd3, 8'h22);
    write_mem(3'd3, 8'h33);
    read_check(3'd3, 8'h33, "T3_overwrite_addr3");
endtask

// T4: reset after writing -> confirm memory cleared
task automatic test_T4_reset_clears();
    write_mem(3'd2, 8'hAA);
    write_mem(3'd5, 8'h55);
    apply_reset();
    read_check(3'd2, 8'h00, "T4_reset_clears_addr2");
    read_check(3'd5, 8'h00, "T4_reset_clears_addr5");
endtask

// T5: read every address after reset -> confirm all 0x00
task automatic test_T5_read_after_reset();
    string tname;
    int    i;
    apply_reset();
    for (i = 0; i < 8; i = i + 1) begin
        tname = $sformatf("T5_read_after_reset_addr%0d", i);
        read_check(i[2:0], 8'h00, tname);
    end
endtask

// ============================================================
// Constrained-random test (50 ops)
// ============================================================
task automatic test_random_50();
    logic [2:0] r_addr;
    logic [7:0] r_data;
    logic       r_we;
    string      tname;
    int         i;

    for (i = 0; i < 50; i = i + 1) begin
        r_addr = $urandom_range(0, 7);
        r_data = $urandom_range(0, 255);
        r_we   = $urandom_range(0, 1);

        if (r_we) begin
            write_mem(r_addr, r_data);
        end
        else begin
            tname = $sformatf("TR_random_op%0d_read_addr%0d", i, r_addr);
            read_check(r_addr, shadow_mem[r_addr], tname);
        end
    end
endtask

// ============================================================
// Orchestrator
// ============================================================
task automatic run_all_tests();
    $display("--- Running directed tests ---");
    test_T1_basic();
    test_T2_all_addresses();
    test_T3_overwrite();
    test_T4_reset_clears();
    test_T5_read_after_reset();

    $display("--- Running constrained-random test (50 ops) ---");
    test_random_50();
endtask