
`timescale 1ns/1ps

module tb_cpu_logic;

    logic clk;
    logic reset;

    logic [15:0] pc;
    logic [2:0] state;
    logic halted;
    logic illegal_instruction;

    integer cycles;

    localparam [2:0] STATE_HALTED = 3'd5;

    cpu #(
        .INSTRUCTION_INIT_FILE("programs/binaries/logic.hex")
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

        if (dut.register_file_instance.registers[2] !== 8'd10) begin
            $display("FAIL: R2 expected 10, got %d",
                dut.register_file_instance.registers[2]);
            $fatal(1);
        end

        if (dut.register_file_instance.registers[3] !== 8'd8) begin
            $display("FAIL: AND expected 8, got %d",
                dut.register_file_instance.registers[3]);
            $fatal(1);
        end

        if (dut.register_file_instance.registers[4] !== 8'd14) begin
            $display("FAIL: OR expected 14, got %d",
                dut.register_file_instance.registers[4]);
            $fatal(1);
        end

        if (dut.register_file_instance.registers[5] !== 8'd6) begin
            $display("FAIL: XOR expected 6, got %d",
                dut.register_file_instance.registers[5]);
            $fatal(1);
        end

        $display("-----------------------------------");
        $display("LOGIC OPERATIONS TEST PASSED");
        $display("-----------------------------------");
        $display("R2 (input): %d", dut.register_file_instance.registers[2]);
        $display("R3 (AND):   %d", dut.register_file_instance.registers[3]);
        $display("R4 (OR):    %d", dut.register_file_instance.registers[4]);
        $display("R5 (XOR):   %d", dut.register_file_instance.registers[5]);
        $display("Cycles:     %d", cycles);
        $display("Status: HALTED");
        $display("-----------------------------------");

        $finish;
    end

endmodule
