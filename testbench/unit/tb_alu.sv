`timescale 1ns/1ps

module tb_alu;

    import cpu_pkg::*;

    logic [7:0] operand_a;
    logic [7:0] operand_b;
    alu_operation_t operation;
    logic [7:0] result;
    flags_t flags;

    alu dut (
        .operand_a(operand_a),
        .operand_b(operand_b),
        .operation(operation),
        .result(result),
        .flags(flags)
    );

    initial begin
        operand_a = 8'd250;
        operand_b = 8'd10;
        operation = ALU_ADD;
        #1;

        if (result !== 8'd4 || flags.carry !== 1'b1)
            $fatal(1, "ALU ADD carry test failed");

        operand_a = 8'd127;
        operand_b = 8'd1;
        operation = ALU_ADD;
        #1;

        if (result !== 8'd128 || flags.overflow !== 1'b1 || flags.negative !== 1'b1)
            $fatal(1, "ALU ADD signed overflow test failed");

        operand_a = 8'd0;
        operand_b = 8'd1;
        operation = ALU_SUB;
        #1;

        if (result !== 8'd255 || flags.carry !== 1'b0 || flags.negative !== 1'b1)
            $fatal(1, "ALU SUB borrow test failed");

        operand_a = 8'd128;
        operand_b = 8'd1;
        operation = ALU_SUB;
        #1;

        if (result !== 8'd127 || flags.overflow !== 1'b1)
            $fatal(1, "ALU SUB signed overflow test failed");

        operand_a = 8'b10101010;
        operand_b = 8'b11001100;
        operation = ALU_AND;
        #1;

        if (result !== 8'b10001000)
            $fatal(1, "ALU AND test failed");

        operation = ALU_OR;
        #1;

        if (result !== 8'b11101110)
            $fatal(1, "ALU OR test failed");

        operation = ALU_XOR;
        #1;

        if (result !== 8'b01100110)
            $fatal(1, "ALU XOR test failed");

        operation = ALU_PASS;
        #1;

        if (result !== operand_a)
            $fatal(1, "ALU PASS test failed");

        operand_a = 8'd0;
        operand_b = 8'd0;
        operation = ALU_ADD;
        #1;

        if (result !== 8'd0 || flags.zero !== 1'b1)
            $fatal(1, "ALU ZERO flag test failed");

        $display("ALU UNIT TEST PASSED");
        $finish;
    end

endmodule
