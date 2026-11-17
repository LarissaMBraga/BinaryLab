`timescale 1ns/1ps

module tb_cpu_runner;

    logic clk;
    logic reset;

    logic [7:0] gpio_input;
    logic [7:0] gpio_output;
    logic [7:0] gpio_direction;

    logic [15:0] pc;
    logic [2:0] state;
    logic halted;
    logic illegal_instruction;

    integer cycles;
    integer index;

    localparam integer MAX_CYCLES = 1000;
    localparam [2:0] STATE_HALTED = 3'd5;

    cpu #(
        .INSTRUCTION_INIT_FILE("build/extended_isa.bin"),
        .INSTRUCTION_INIT_FORMAT("BIN")
    ) dut (
        .clk(clk),
        .reset(reset),
        .gpio_input(gpio_input),
        .gpio_output(gpio_output),
        .gpio_direction(gpio_direction),
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
        gpio_input = 8'h00;

        repeat (2) @(negedge clk);
        reset = 1'b0;

        while (!halted && !illegal_instruction && cycles < MAX_CYCLES) begin
            @(negedge clk);
            cycles = cycles + 1;
        end

        #1;

        if (illegal_instruction) begin
            $display("EXECUTION_ERROR=ILLEGAL_INSTRUCTION");
            $display("PC=%0d", pc);
            $finish;
        end

        if (!halted || state !== STATE_HALTED) begin
            $display("EXECUTION_ERROR=TIMEOUT");
            $display("PC=%0d", pc);
            $display("CYCLES=%0d", cycles);
            $finish;
        end

        $display("EXECUTION_STATUS=HALTED");

        for (index = 0; index < 8; index = index + 1) begin
            $display(
                "REGISTER_R%0d=%0d",
                index,
                dut.register_file_instance.registers[index]
            );
        end

        $display("PC=%0d", pc);
        $display("CYCLES=%0d", cycles);
        $display("GPIO_OUTPUT=%0d", gpio_output);
        $display("GPIO_DIRECTION=%0d", gpio_direction);

        $display("EXECUTION_COMPLETE=1");
        $finish;
    end

endmodule
