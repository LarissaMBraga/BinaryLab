`timescale 1ns/1ps

module tb_cpu_control_flow;

    logic clk;
    logic reset;
    logic [15:0] pc;
    logic [2:0] state;
    logic halted;
    logic illegal_instruction;
    integer cycles;

    cpu #(
        .INSTRUCTION_INIT_FILE("build/control_flow_c.bin"),
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

        if (pc !== 16'd0)
            $fatal(1, "CPU PC did not reset to zero");

        while (!halted && !illegal_instruction && cycles < 200) begin
            @(negedge clk);
            cycles = cycles + 1;
        end

        #1;

        if (illegal_instruction)
            $fatal(1, "Illegal instruction during control flow test");

        if (!halted)
            $fatal(1, "Control flow program did not halt");

        if (dut.register_file_instance.registers[1] !== 8'd5)
            $fatal(1, "Control flow R1 mismatch");

        if (dut.register_file_instance.registers[2] !== 8'd6)
            $fatal(1, "Control flow R2 mismatch");

        if (dut.register_file_instance.registers[3] !== 8'd10)
            $fatal(1, "BEQ failed: R3 should be 10");

        if (dut.register_file_instance.registers[4] !== 8'd0)
            $fatal(1, "BNE path failed: R4 should remain zero");

        if (dut.register_file_instance.registers[5] !== 8'd0)
            $fatal(1, "JMP failed: skipped instruction modified R5");

        $display("CPU CONTROL FLOW TEST PASSED");
        $display("BEQ, BNE and JMP verified");
        $display("Cycles: %0d", cycles);

        $finish;
    end

endmodule
