`timescale 1ns/1ps

module tb_cpu_invalid_instruction;

    logic clk;
    logic reset;
    logic [15:0] pc;
    logic [2:0] state;
    logic halted;
    logic illegal_instruction;
    integer cycles;

    cpu #(
        .INSTRUCTION_INIT_FILE("build/invalid_opcode.bin"),
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

        while (!illegal_instruction && !halted && cycles < 20) begin
            @(negedge clk);
            cycles = cycles + 1;
        end

        #1;

        if (!illegal_instruction)
            $fatal(1, "CPU did not reject invalid opcode");

        if (halted)
            $fatal(1, "CPU halted instead of entering ILLEGAL state");

        if (state !== 3'd6)
            $fatal(1, "CPU did not enter ILLEGAL state");

        $display("CPU INVALID INSTRUCTION TEST PASSED");
        $finish;
    end

endmodule
