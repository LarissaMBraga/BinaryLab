`timescale 1ns/1ps

module tb_cpu_memory_offsets;

    logic clk;
    logic reset;
    logic [15:0] pc;
    logic [2:0] state;
    logic halted;
    logic illegal_instruction;
    integer cycles;

    cpu #(
        .INSTRUCTION_INIT_FILE("build/memory_offsets_c.bin"),
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

        if (illegal_instruction)
            $fatal(1, "Illegal instruction during memory test");

        if (!halted)
            $fatal(1, "Memory program did not halt");

        if (dut.register_file_instance.registers[1] !== 8'd42)
            $fatal(1, "Memory test R1 mismatch");

        if (dut.register_file_instance.registers[3] !== 8'd42)
            $fatal(1, "Negative offset load failed");

        if (dut.register_file_instance.registers[4] !== 8'd42)
            $fatal(1, "Positive offset load failed");

        if (dut.memory_bus_instance.data_memory_instance.memory[10] !== 8'd42)
            $fatal(1, "Negative offset store failed");

        if (dut.memory_bus_instance.data_memory_instance.memory[15] !== 8'd42)
            $fatal(1, "Positive offset store failed");

        $display("CPU MEMORY OFFSET TEST PASSED");
        $display("Positive and negative offsets verified");

        $finish;
    end

endmodule
