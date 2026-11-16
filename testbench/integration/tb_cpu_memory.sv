
`timescale 1ns/1ps

module tb_cpu_memory;

    logic clk;
    logic reset;

    logic [15:0] pc;
    logic [2:0] state;
    logic halted;
    logic illegal_instruction;

    integer cycles;

    localparam [2:0] STATE_HALTED = 3'd5;

    cpu #(
        .INSTRUCTION_INIT_FILE("programs/binaries/memory.hex")
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

        while (!halted && !illegal_instruction && cycles < 100) begin
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

        if (dut.register_file_instance.registers[1] !== 8'd42) begin
            $display("FAIL: R1 expected 42, got %d",
                dut.register_file_instance.registers[1]);
            $fatal(1);
        end

        if (dut.register_file_instance.registers[2] !== 8'd10) begin
            $display("FAIL: R2 expected 10, got %d",
                dut.register_file_instance.registers[2]);
            $fatal(1);
        end

        if (dut.register_file_instance.registers[3] !== 8'd42) begin
            $display("FAIL: LD expected 42 in R3, got %d",
                dut.register_file_instance.registers[3]);
            $fatal(1);
        end

        if (dut.memory_bus_instance.data_memory_instance.memory[10] !== 8'd42) begin
            $display("FAIL: Memory address 10 expected 42, got %d",
                dut.memory_bus_instance.data_memory_instance.memory[10]);
            $fatal(1);
        end

        $display("-----------------------------------");
        $display("MEMORY OPERATIONS TEST PASSED");
        $display("-----------------------------------");
        $display("R1:          %d", dut.register_file_instance.registers[1]);
        $display("R2:          %d", dut.register_file_instance.registers[2]);
        $display("R3 (LD):     %d", dut.register_file_instance.registers[3]);
        $display("Memory[10]:  %d", dut.memory_bus_instance.data_memory_instance.memory[10]);
        $display("Cycles:      %d", cycles);
        $display("Status: HALTED");
        $display("-----------------------------------");

        $finish;
    end

endmodule
