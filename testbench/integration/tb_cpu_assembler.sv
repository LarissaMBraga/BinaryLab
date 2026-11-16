`timescale 1ns/1ps

module tb_cpu_assembler;

    logic clk;
    logic reset;

    logic [15:0] pc;
    logic [2:0] state;
    logic halted;
    logic illegal_instruction;

    integer cycles;

    localparam [2:0] STATE_HALTED = 3'd5;

    cpu #(
        .INSTRUCTION_INIT_FILE("programs/binaries/arithmetic.hex")
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

        if (dut.register_file_instance.registers[1] !== 8'd30) begin
            $display("FAIL: R1 expected 30, got %d",
                dut.register_file_instance.registers[1]);
            $fatal(1);
        end

        if (dut.register_file_instance.registers[2] !== 8'd20) begin
            $display("FAIL: R2 expected 20, got %d",
                dut.register_file_instance.registers[2]);
            $fatal(1);
        end

        $display("-----------------------------------");
        $display("ASSEMBLER CPU INTEGRATION TEST PASSED");
        $display("-----------------------------------");
        $display("R1:     %d", dut.register_file_instance.registers[1]);
        $display("R2:     %d", dut.register_file_instance.registers[2]);
        $display("PC:     %d", pc);
        $display("Cycles: %d", cycles);
        $display("Status: HALTED");
        $display("-----------------------------------");

        $finish;
    end

endmodule