
`timescale 1ns/1ps

module tb_instruction_memory_binary;

    logic read_enable;
    logic [15:0] address;
    logic [15:0] instruction;

    integer test_count;
    integer passed_count;

    instruction_memory #(
        .MEMORY_DEPTH(65536),
        .INIT_FILE("programs/binaries/arithmetic.bin"),
        .INIT_FORMAT("BIN")
    ) dut (
        .read_enable(read_enable),
        .address(address),
        .instruction(instruction)
    );

    task automatic check(
        input logic [15:0] expected,
        input string test_name
    );
        begin
            test_count = test_count + 1;

            if (instruction === expected) begin
                passed_count = passed_count + 1;
                $display("PASS: %s", test_name);
            end else begin
                $display(
                    "FAIL: %s | Expected: %04h | Got: %04h",
                    test_name,
                    expected,
                    instruction
                );
                $fatal(1);
            end
        end
    endtask

    initial begin
        test_count = 0;
        passed_count = 0;

        read_enable = 1'b0;
        address = 16'h0000;

        #1;

        $display("-----------------------------------");
        $display("BINARY INSTRUCTION MEMORY TEST");
        $display("-----------------------------------");

        read_enable = 1'b1;

        address = 16'h0000;
        #1;
        check(16'h820A, "Reads first binary instruction");

        address = 16'h0002;
        #1;
        check(16'h8414, "Reads second binary instruction");

        address = 16'h0004;
        #1;
        check(16'h3280, "Reads third binary instruction");

        address = 16'h0006;
        #1;
        check(16'h1000, "Reads fourth binary instruction");

        read_enable = 1'b0;
        address = 16'h0000;
        #1;
        check(16'h0000, "Disabled read returns zero");

        $display("-----------------------------------");
        $display(
            "BINARY MEMORY: %0d/%0d TESTS PASSED",
            passed_count,
            test_count
        );
        $display("-----------------------------------");

        $finish;
    end

endmodule
