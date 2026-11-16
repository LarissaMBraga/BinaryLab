
module tb_cpu_control_flow;

    logic clk;
    logic reset;

    logic [15:0] pc;
    logic [2:0] state;
    logic halted;
    logic illegal_instruction;

    integer cycles;

    cpu dut (
        .clk(clk),
        .reset(reset),
        .pc(pc),
        .state(state),
        .halted(halted),
        .illegal_instruction(illegal_instruction)
    );

    always #5 clk = ~clk;

    task write_instruction(
        input integer address,
        input logic [15:0] instruction
    );
        begin
            dut.instruction_memory_instance.memory[address] =
                instruction[15:8];

            dut.instruction_memory_instance.memory[address + 1] =
                instruction[7:0];
        end
    endtask

    task wait_for_halt;
        begin
            cycles = 0;

            while (!halted && !illegal_instruction && cycles < 100) begin
                @(negedge clk);
                cycles = cycles + 1;
            end

            #1;

            if (illegal_instruction) begin
                $display("FAIL: CPU encountered an illegal instruction.");
                $fatal(1);
            end

            if (!halted) begin
                $display("FAIL: CPU did not halt within 100 cycles.");
                $fatal(1);
            end
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        cycles = 0;

        // TEST 1:
        // BEQ taken
        // BNE taken
        // BNE not taken
        // JMP forward
        // All offsets are positive.

        write_instruction(0,  16'h8201); // ADDI R1, 1
        write_instruction(2,  16'hE240); // CMP R1, R1
        write_instruction(4,  16'hC002); // BEQ +2

        write_instruction(6,  16'h8463); // ADDI R2, 99 (skipped)
        write_instruction(8,  16'h8462); // ADDI R2, 98 (skipped)

        write_instruction(10, 16'h8407); // ADDI R2, 7
        write_instruction(12, 16'hE200); // CMP R1, R0
        write_instruction(14, 16'hD002); // BNE +2

        write_instruction(16, 16'h8663); // ADDI R3, 99 (skipped)
        write_instruction(18, 16'h8662); // ADDI R3, 98 (skipped)

        write_instruction(20, 16'h8605); // ADDI R3, 5
        write_instruction(22, 16'hB002); // JMP +2

        write_instruction(24, 16'h8863); // ADDI R4, 99 (skipped)
        write_instruction(26, 16'h8862); // ADDI R4, 98 (skipped)

        write_instruction(28, 16'h8804); // ADDI R4, 4
        write_instruction(30, 16'hE240); // CMP R1, R1
        write_instruction(32, 16'hD002); // BNE +2 (not taken)

        write_instruction(34, 16'h8A06); // ADDI R5, 6
        write_instruction(36, 16'hB001); // JMP +1
        write_instruction(38, 16'h8A63); // ADDI R5, 99 (skipped)

        write_instruction(40, 16'h1000); // HALT

        repeat (2) @(negedge clk);
        reset = 1'b0;

        wait_for_halt();

        if (dut.register_file_instance.registers[1] !== 8'd1) begin
            $display("FAIL: Test 1 - R1 expected 1, got %d",
                dut.register_file_instance.registers[1]);
            $fatal(1);
        end

        if (dut.register_file_instance.registers[2] !== 8'd7) begin
            $display("FAIL: Test 1 - R2 expected 7, got %d",
                dut.register_file_instance.registers[2]);
            $fatal(1);
        end

        if (dut.register_file_instance.registers[3] !== 8'd5) begin
            $display("FAIL: Test 1 - R3 expected 5, got %d",
                dut.register_file_instance.registers[3]);
            $fatal(1);
        end

        if (dut.register_file_instance.registers[4] !== 8'd4) begin
            $display("FAIL: Test 1 - R4 expected 4, got %d",
                dut.register_file_instance.registers[4]);
            $fatal(1);
        end

        if (dut.register_file_instance.registers[5] !== 8'd6) begin
            $display("FAIL: Test 1 - R5 expected 6, got %d",
                dut.register_file_instance.registers[5]);
            $fatal(1);
        end

        $display("-----------------------------------");
        $display("CONTROL FLOW TEST 1 PASSED");
        $display("BEQ, BNE and JMP forward verified");
        $display("-----------------------------------");

        // TEST 2:
        // JMP forward followed by JMP backward.
        // The backward jump must return to address 2.

        reset = 1'b1;

        write_instruction(0,  16'hB003); // JMP +3 -> address 8
        write_instruction(2,  16'h8207); // ADDI R1, 7
        write_instruction(4,  16'hB004); // JMP +4 -> address 14
        write_instruction(6,  16'h8463); // ADDI R2, 99 (skipped)
        write_instruction(8,  16'hBFFC); // JMP -4 -> address 2

        write_instruction(10, 16'h8663); // ADDI R3, 99 (skipped)
        write_instruction(12, 16'h8863); // ADDI R4, 99 (skipped)
        write_instruction(14, 16'h1000); // HALT

        repeat (2) @(negedge clk);
        reset = 1'b0;

        wait_for_halt();

        if (dut.register_file_instance.registers[1] !== 8'd7) begin
            $display("FAIL: Test 2 - R1 expected 7, got %d",
                dut.register_file_instance.registers[1]);
            $fatal(1);
        end

        if (dut.register_file_instance.registers[2] !== 8'd0) begin
            $display("FAIL: Test 2 - R2 expected 0, got %d",
                dut.register_file_instance.registers[2]);
            $fatal(1);
        end

        if (dut.register_file_instance.registers[3] !== 8'd0) begin
            $display("FAIL: Test 2 - R3 expected 0, got %d",
                dut.register_file_instance.registers[3]);
            $fatal(1);
        end

        if (dut.register_file_instance.registers[4] !== 8'd0) begin
            $display("FAIL: Test 2 - R4 expected 0, got %d",
                dut.register_file_instance.registers[4]);
            $fatal(1);
        end

        $display("-----------------------------------");
        $display("CONTROL FLOW TEST 2 PASSED");
        $display("Negative JMP offset verified");
        $display("-----------------------------------");

        $display("");
        $display("ALL CONTROL FLOW TESTS PASSED");
        $display("Status: HALTED");
        $display("PC: %d", pc);
        $display("-----------------------------------");

        $finish;
    end

endmodule
