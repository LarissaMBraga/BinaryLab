
`timescale 1ns/1ps

module tb_instruction_memory;

    logic read_enable;
    logic [15:0] address;
    logic [15:0] instruction;

    integer test_count;
    integer passed_count;

    instruction_memory dut (
        .read_enable(read_enable),
        .address(address),
        .instruction(instruction)
    );

    task automatic check(
        input logic condition,
        input string test_name
    );
        begin
            test_count = test_count + 1;

            if (condition === 1'b1) begin
                passed_count = passed_count + 1;
                $display("PASS: %s", test_name);
            end else begin
                $display("FAIL: %s", test_name);
                $fatal(1);
            end
        end
    endtask

    initial begin
        test_count = 0;
        passed_count = 0;
        read_enable = 1'b0;
        address = 16'h0000;

        dut.memory[16'h0000] = 8'h32;
        dut.memory[16'h0001] = 8'h80;
        dut.memory[16'h0002] = 8'hA5;
        dut.memory[16'h0003] = 8'h3C;
        dut.memory[16'hFFFE] = 8'h12;
        dut.memory[16'hFFFF] = 8'h34;

        $display("Starting Instruction Memory tests...");

        #1;
        check(instruction == 16'h0000,
              "Disabled read returns zero");

        read_enable = 1'b1;
        address = 16'h0000;
        #1;
        check(instruction == 16'h3280,
              "Reads instruction in big-endian order");

        address = 16'h0002;
        #1;
        check(instruction == 16'hA53C,
              "Reads consecutive instructions");

        address = 16'hFFFE;
        #1;
        check(instruction == 16'h1234,
              "Reads instruction at last valid address");

        address = 16'hFFFF;
        #1;
        check(instruction == 16'h0000,
              "Rejects final address without a second byte");

        read_enable = 1'b0;
        address = 16'h0000;
        #1;
        check(instruction == 16'h0000,
              "Read enable disables instruction output");

        $display(
            "Instruction Memory: %0d/%0d tests passed.",
            passed_count,
            test_count
        );

        $finish;
    end

endmodule
