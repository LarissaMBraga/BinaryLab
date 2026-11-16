`timescale 1ns/1ps

module tb_alu;

    import cpu_pkg::*;

    logic [DATA_WIDTH-1:0] operand_a;
    logic [DATA_WIDTH-1:0] operand_b;

    alu_operation_t operation;

    logic [DATA_WIDTH-1:0] result;
    flags_t flags;

    integer tests_passed;

    alu dut (
        .operand_a(operand_a),
        .operand_b(operand_b),
        .operation(operation),
        .result(result),
        .flags(flags)
    );

    task automatic check_operation(
        input alu_operation_t test_operation,
        input logic [7:0] test_a,
        input logic [7:0] test_b,
        input logic [7:0] expected_result,
        input logic [3:0] expected_flags,
        input string test_name
    );
        begin
            operation = test_operation;
            operand_a = test_a;
            operand_b = test_b;

            #1;

            if (
                result !== expected_result ||
                {flags.zero, flags.carry, flags.negative, flags.overflow}
                    !== expected_flags
            ) begin
                $display("FAILED: %s", test_name);
                $display("Expected result: %h | Actual: %h",
                         expected_result, result);
                $display("Expected flags: %b | Actual: %b",
                         expected_flags,
                         {flags.zero, flags.carry,
                          flags.negative, flags.overflow});

                $fatal(1, "ALU verification failed.");
            end

            tests_passed = tests_passed + 1;

            $display("PASSED: %s", test_name);
        end
    endtask

    initial begin
        tests_passed = 0;

        operand_a = '0;
        operand_b = '0;
        operation = ALU_PASS;

        $display("--------------------------------");
        $display("BINARY LAB - ALU TESTBENCH");
        $display("--------------------------------");

        check_operation(
            ALU_ADD, 8'h05, 8'h03, 8'h08, 4'b0000,
            "Addition"
        );

        check_operation(
            ALU_ADD, 8'h7F, 8'h01, 8'h80, 4'b0011,
            "Addition signed overflow"
        );

        check_operation(
            ALU_ADD, 8'hFF, 8'h01, 8'h00, 4'b1100,
            "Addition carry"
        );

        check_operation(
            ALU_SUB, 8'h05, 8'h03, 8'h02, 4'b0100,
            "Subtraction"
        );

        check_operation(
            ALU_SUB, 8'h00, 8'h01, 8'hFF, 4'b0010,
            "Subtraction borrow"
        );

        check_operation(
            ALU_SUB, 8'h05, 8'h05, 8'h00, 4'b1100,
            "Subtraction zero"
        );

        check_operation(
            ALU_SUB, 8'h80, 8'h01, 8'h7F, 4'b0101,
            "Subtraction signed overflow"
        );

        check_operation(
            ALU_AND, 8'hF0, 8'h0F, 8'h00, 4'b1000,
            "Bitwise AND"
        );

        check_operation(
            ALU_OR, 8'h80, 8'h01, 8'h81, 4'b0010,
            "Bitwise OR"
        );

        check_operation(
            ALU_XOR, 8'hFF, 8'hFF, 8'h00, 4'b1000,
            "Bitwise XOR"
        );

        check_operation(
            ALU_PASS, 8'h80, 8'h00, 8'h80, 4'b0010,
            "Pass operand"
        );

        $display("--------------------------------");
        $display("Tests passed: %0d", tests_passed);
        $display("All ALU tests completed.");
        $display("--------------------------------");

        $finish;
    end

endmodule