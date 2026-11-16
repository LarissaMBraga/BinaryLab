`timescale 1ns/1ps

module tb_program_counter;

    import cpu_pkg::*;

    logic clk;
    logic reset;
    logic enable;
    logic load_enable;
    logic [ADDRESS_WIDTH-1:0] load_address;
    logic [ADDRESS_WIDTH-1:0] pc;

    integer test_count;

    program_counter dut (
        .clk(clk),
        .reset(reset),
        .enable(enable),
        .load_enable(load_enable),
        .load_address(load_address),
        .pc(pc)
    );

    always #5 clk = ~clk;

    task automatic check_pc(
        input logic [ADDRESS_WIDTH-1:0] expected,
        input string test_name
    );
        begin
            #1;
            test_count = test_count + 1;

            if (pc !== expected) begin
                $display(
                    "FAIL: %s | Expected: %h | Received: %h",
                    test_name,
                    expected,
                    pc
                );
                $fatal(1);
            end

            $display("PASS: %s | PC = %h", test_name, pc);
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b0;
        enable = 1'b0;
        load_enable = 1'b0;
        load_address = '0;
        test_count = 0;

        $display("Starting Program Counter tests...");

        $display("Testing asynchronous reset...");

        reset = 1'b1;
        check_pc(16'h0000, "Reset initializes PC to zero");

        reset = 1'b0;

        $display("Testing increment...");

        @(negedge clk);
        enable = 1'b1;

        @(posedge clk);
        check_pc(16'h0002, "First increment");

        @(posedge clk);
        check_pc(16'h0004, "Second increment");

        @(posedge clk);
        check_pc(16'h0006, "Third increment");

        $display("Testing disabled counter...");

        @(negedge clk);
        enable = 1'b0;

        repeat (2) @(posedge clk);
        check_pc(16'h0006, "PC holds when disabled");

        $display("Testing address loading...");

        @(negedge clk);
        load_enable = 1'b1;
        load_address = 16'h1234;

        @(posedge clk);
        check_pc(16'h1234, "Load jumps to requested address");

        @(negedge clk);
        load_enable = 1'b0;
        enable = 1'b1;

        @(posedge clk);
        check_pc(16'h1236, "Increment after address load");

        $display("Testing load priority over increment...");

        @(negedge clk);
        load_enable = 1'b1;
        load_address = 16'hABCD;
        enable = 1'b1;

        @(posedge clk);
        check_pc(16'hABCD, "Load takes priority over increment");

        $display("Testing asynchronous reset from nonzero address...");

        #1;
        reset = 1'b1;
        check_pc(16'h0000, "Reset clears PC immediately");

        reset = 1'b0;
        enable = 1'b0;
        load_enable = 1'b0;

        $display("--------------------------------");
        $display("All %0d Program Counter checks passed!", test_count);
        $display("--------------------------------");

        $finish;
    end

endmodule