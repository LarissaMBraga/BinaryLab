
module tb_cpu_illegal;

    logic clk;
    logic reset;

    logic [15:0] pc;
    logic [2:0] state;
    logic halted;
    logic illegal_instruction;

    integer cycles;

    localparam logic [2:0] STATE_ILLEGAL = 3'd6;

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
        // EXT (illegal instruction)

        dut.instruction_memory_instance.memory[0] = 8'hF0;
        dut.instruction_memory_instance.memory[1] = 8'h00;

        repeat (2) @(negedge clk);
        reset = 1'b0;

        while (!illegal_instruction && cycles < 20) begin
            @(negedge clk);
            cycles = cycles + 1;
        end

        #1;

        if (!illegal_instruction) begin
            $display("FAIL: CPU did not detect the illegal instruction.");
            $fatal(1);
        end

        if (state !== STATE_ILLEGAL) begin
            $display("FAIL: Expected ILLEGAL state, got %d", state);
            $fatal(1);
        end

        if (halted) begin
            $display("FAIL: CPU incorrectly entered HALTED state.");
            $fatal(1);
        end

        repeat (5) @(negedge clk);

        if (state !== STATE_ILLEGAL) begin
            $display("FAIL: CPU did not remain in ILLEGAL state.");
            $fatal(1);
        end

        if (!illegal_instruction) begin
            $display("FAIL: Illegal instruction signal was not maintained.");
            $fatal(1);
        end

        $display("-----------------------------------");
        $display("CPU ILLEGAL INSTRUCTION TEST PASSED");
        $display("-----------------------------------");
        $display("State:       %d", state);
        $display("Illegal:     %b", illegal_instruction);
        $display("Halted:      %b", halted);
        $display("PC:          %d", pc);
        $display("Cycles:      %d", cycles);
        $display("Status:      ILLEGAL");
        $display("-----------------------------------");

        $finish;
    end

endmodule
