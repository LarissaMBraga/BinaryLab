`timescale 1ns/1ps

module tb_cpu_gpio;

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

    cpu #(
        .INSTRUCTION_INIT_FILE("build/gpio_c.bin"),
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
        gpio_input = 8'h0A;

        repeat (2) @(negedge clk);
        reset = 1'b0;

        for (cycles = 0; cycles < 200; cycles = cycles + 1) begin
            @(posedge clk);
            #1;

            if (illegal_instruction) begin
                $fatal(1, "CPU rejected the GPIO test program");
            end

            if (halted) begin
                if (gpio_direction !== 8'h05)
                    $fatal(1, "GPIO direction register test failed");

                if (gpio_output !== 8'h05)
                    $fatal(1, "GPIO output register test failed");

                if (dut.memory_bus_instance.data_memory_instance.memory[10] !== 8'h0F)
                    $fatal(1, "GPIO input/output readback test failed");

                $display("GPIO MEMORY-MAPPED I/O TEST PASSED");
                $finish;
            end
        end

        $fatal(1, "CPU did not halt during GPIO test");
    end

endmodule