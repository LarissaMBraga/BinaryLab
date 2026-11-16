
module tb_cpu;

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
        // ADD  R1, R2
        // ST   R1, [R0+0]
        // LD   R3, [R0+0]
        // CMP  R3, R1
        // HALT

        dut.instruction_memory_instance.memory[0]  = 8'h82;
        dut.instruction_memory_instance.memory[1]  = 8'h05;

        dut.instruction_memory_instance.memory[2]  = 8'h84;
        dut.instruction_memory_instance.memory[3]  = 8'h03;

        dut.instruction_memory_instance.memory[4]  = 8'h32;
        dut.instruction_memory_instance.memory[5]  = 8'h80;

        dut.instruction_memory_instance.memory[6]  = 8'hA2;
        dut.instruction_memory_instance.memory[7]  = 8'h00;

        dut.instruction_memory_instance.memory[8]  = 8'h96;
        dut.instruction_memory_instance.memory[9]  = 8'h00;

        dut.instruction_memory_instance.memory[10] = 8'hE6;
        dut.instruction_memory_instance.memory[11] = 8'h40;

        dut.instruction_memory_instance.memory[12] = 8'h10;
        dut.instruction_memory_instance.memory[13] = 8'h00;

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

        if (dut.register_file_instance.registers[1] !== 8'd8) begin
            $display("FAIL: R1 expected 8, got %d",
                dut.register_file_instance.registers[1]);
            $fatal(1);
        end

        if (dut.register_file_instance.registers[2] !== 8'd3) begin
            $display("FAIL: R2 expected 3, got %d",
                dut.register_file_instance.registers[2]);
            $fatal(1);
        end

        if (dut.register_file_instance.registers[3] !== 8'd8) begin
            $display("FAIL: R3 expected 8, got %d",
                dut.register_file_instance.registers[3]);
            $fatal(1);
        end

        if (dut.data_memory_instance.memory[0] !== 8'd8) begin
            $display("FAIL: Memory[0] expected 8, got %d",
                dut.data_memory_instance.memory[0]);
            $fatal(1);
        end

        if (dut.flags_register.zero !== 1'b1) begin
            $display("FAIL: Zero flag was expected to be 1.");
            $fatal(1);
        end

        $display("-----------------------------------");
        $display("CPU INTEGRATION TEST PASSED");
        $display("-----------------------------------");
        $display("R1:       %d", dut.register_file_instance.registers[1]);
        $display("R2:       %d", dut.register_file_instance.registers[2]);
        $display("R3:       %d", dut.register_file_instance.registers[3]);
        $display("Memory 0: %d", dut.data_memory_instance.memory[0]);
        $display("Zero flag: %b", dut.flags_register.zero);
        $display("PC:        %d", pc);
        $display("Cycles:    %d", cycles);
        $display("Status:    HALTED");
        $display("-----------------------------------");

        $finish;
    end

endmodule
