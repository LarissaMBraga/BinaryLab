`timescale 1ns/1ps

module tb_cpu_all_instructions;

    logic clk;
    logic reset;

    logic [15:0] pc;
    logic [2:0] state;
    logic halted;
    logic illegal_instruction;

    integer cycles;

    localparam [2:0] STATE_HALTED = 3'd5;

    cpu #(
        .INSTRUCTION_INIT_FILE("build/all_instructions_c.bin"),
        .INSTRUCTION_INIT_FORMAT("BIN")
    ) dut (
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

        repeat (2) @(negedge clk);
        reset = 1'b0;

        while (!halted && !illegal_instruction && cycles < 200) begin
            @(negedge clk);
            cycles = cycles + 1;
        end

        #1;

        if (illegal_instruction) begin
            $display("FAIL: CPU encountered an illegal instruction.");
            $fatal(1);
        end

        if (!halted || state !== STATE_HALTED) begin
            $display("FAIL: CPU did not reach HALTED state.");
            $fatal(1);
        end

        if (dut.register_file_instance.registers[1] !== 8'd10) begin
            $display("FAIL: R1 expected 10, got %d",
                dut.register_file_instance.registers[1]);
            $fatal(1);
        end

        if (dut.register_file_instance.registers[2] !== 8'd5) begin
            $display("FAIL: R2 expected 5, got %d",
                dut.register_file_instance.registers[2]);
            $fatal(1);
        end

        if (dut.register_file_instance.registers[3] !== 8'd15) begin
            $display("FAIL: R3 expected 15, got %d",
                dut.register_file_instance.registers[3]);
            $fatal(1);
        end

        if (dut.register_file_instance.registers[4] !== 8'd10) begin
            $display("FAIL: R4 expected 10, got %d",
                dut.register_file_instance.registers[4]);
            $fatal(1);
        end

        if (dut.register_file_instance.registers[5] !== 8'd15) begin
            $display("FAIL: R5 expected 15, got %d",
                dut.register_file_instance.registers[5]);
            $fatal(1);
        end

        if (dut.register_file_instance.registers[6] !== 8'd0) begin
            $display("FAIL: R6 expected 0, got %d",
                dut.register_file_instance.registers[6]);
            $fatal(1);
        end

        if (dut.data_memory_instance.memory[11] !== 8'd15) begin
            $display("FAIL: Memory[11] expected 15, got %d",
                dut.data_memory_instance.memory[11]);
            $fatal(1);
        end

        $display("---------------------------------------");
        $display("ALL INSTRUCTIONS CPU TEST PASSED");
        $display("---------------------------------------");
        $display("R1:        %d", dut.register_file_instance.registers[1]);
        $display("R2:        %d", dut.register_file_instance.registers[2]);
        $display("R3:        %d", dut.register_file_instance.registers[3]);
        $display("R4:        %d", dut.register_file_instance.registers[4]);
        $display("R5:        %d", dut.register_file_instance.registers[5]);
        $display("R6:        %d", dut.register_file_instance.registers[6]);
        $display("Memory[11]: %d", dut.data_memory_instance.memory[11]);
        $display("PC:        %d", pc);
        $display("Cycles:    %d", cycles);
        $display("Status:    HALTED");
        $display("---------------------------------------");

        $finish;
    end

endmodule