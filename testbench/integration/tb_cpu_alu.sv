
module tb_cpu_alu;

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

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        cycles = 0;

        // Program:
        // ADDI R1, 5
        // ADDI R2, 3
        // SUB  R1, R2  -> 2
        // AND  R1, R2  -> 2
        // OR   R1, R2  -> 3
        // XOR  R1, R2  -> 0
        // ADDI R1, 1   -> 1
        // SUB  R1, R2  -> 254 (negative)
        // HALT

        dut.instruction_memory_instance.memory[0]  = 8'h82;
        dut.instruction_memory_instance.memory[1]  = 8'h05;

        dut.instruction_memory_instance.memory[2]  = 8'h84;
        dut.instruction_memory_instance.memory[3]  = 8'h03;

        dut.instruction_memory_instance.memory[4]  = 8'h42;
        dut.instruction_memory_instance.memory[5]  = 8'h80;

        dut.instruction_memory_instance.memory[6]  = 8'h52;
        dut.instruction_memory_instance.memory[7]  = 8'h80;

        dut.instruction_memory_instance.memory[8]  = 8'h62;
        dut.instruction_memory_instance.memory[9]  = 8'h80;

        dut.instruction_memory_instance.memory[10] = 8'h72;
        dut.instruction_memory_instance.memory[11] = 8'h80;

        dut.instruction_memory_instance.memory[12] = 8'h82;
        dut.instruction_memory_instance.memory[13] = 8'h01;

        dut.instruction_memory_instance.memory[14] = 8'h42;
        dut.instruction_memory_instance.memory[15] = 8'h80;

        dut.instruction_memory_instance.memory[16] = 8'h10;
        dut.instruction_memory_instance.memory[17] = 8'h00;

        repeat (2) @(negedge clk);
        reset = 1'b0;

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

        if (dut.register_file_instance.registers[1] !== 8'hFE) begin
            $display("FAIL: R1 expected 254, got %d",
                dut.register_file_instance.registers[1]);
            $fatal(1);
        end

        if (dut.register_file_instance.registers[2] !== 8'd3) begin
            $display("FAIL: R2 expected 3, got %d",
                dut.register_file_instance.registers[2]);
            $fatal(1);
        end

        if (dut.flags_register.negative !== 1'b1) begin
            $display("FAIL: Negative flag was expected to be 1.");
            $fatal(1);
        end

        if (dut.flags_register.carry !== 1'b0) begin
            $display("FAIL: Carry flag was expected to be 0.");
            $fatal(1);
        end

        if (dut.flags_register.zero !== 1'b0) begin
            $display("FAIL: Zero flag was expected to be 0.");
            $fatal(1);
        end

        $display("-----------------------------------");
        $display("CPU ALU INTEGRATION TEST PASSED");
        $display("-----------------------------------");
        $display("R1:          %d", dut.register_file_instance.registers[1]);
        $display("R2:          %d", dut.register_file_instance.registers[2]);
        $display("Negative:    %b", dut.flags_register.negative);
        $display("Carry:       %b", dut.flags_register.carry);
        $display("Zero:        %b", dut.flags_register.zero);
        $display("Cycles:      %d", cycles);
        $display("Status:      HALTED");
        $display("-----------------------------------");

        $finish;
    end

endmodule
