`timescale 1ns/1ps

module tb_memory_bus;

    logic clk;
    logic reset;

    logic read_enable;
    logic write_enable;
    logic [15:0] address;
    logic [7:0] write_data;
    logic [7:0] read_data;

    logic [7:0] gpio_input;
    logic [7:0] gpio_output;
    logic [7:0] gpio_direction;

    memory_bus #(.DATA_MEMORY_DEPTH(256)) dut (
        .clk(clk),
        .reset(reset),
        .read_enable(read_enable),
        .write_enable(write_enable),
        .address(address),
        .write_data(write_data),
        .read_data(read_data),
        .gpio_input(gpio_input),
        .gpio_output(gpio_output),
        .gpio_direction(gpio_direction)
    );

    always #5 clk = ~clk;

    task automatic write_byte(
        input logic [15:0] target_address,
        input logic [7:0] value
    );
        begin
            @(negedge clk);
            address = target_address;
            write_data = value;
            write_enable = 1'b1;
            @(posedge clk);
            #1;
            write_enable = 1'b0;
        end
    endtask

    task automatic check_read(
        input logic [15:0] target_address,
        input logic [7:0] expected
    );
        begin
            @(negedge clk);
            address = target_address;
            read_enable = 1'b1;
            #1;

            if (read_data !== expected)
                $fatal(
                    1,
                    "Read mismatch at %h: expected %h, got %h",
                    target_address,
                    expected,
                    read_data
                );

            read_enable = 1'b0;
        end
    endtask

    initial begin
        clk = 1'b0;
        reset = 1'b1;
        read_enable = 1'b0;
        write_enable = 1'b0;
        address = 16'h0000;
        write_data = 8'h00;
        gpio_input = 8'hA5;

        repeat (2) @(posedge clk);
        #1;
        reset = 1'b0;

        write_byte(16'h0020, 8'h5A);
        check_read(16'h0020, 8'h5A);

        write_byte(16'h00F1, 8'hFF);

        if (gpio_direction !== 8'hFF)
            $fatal(1, "GPIO direction register write failed.");

        write_byte(16'h00F0, 8'h3C);

        if (gpio_output !== 8'h3C)
            $fatal(1, "GPIO output register write failed.");

        check_read(16'h00F0, 8'h3C);
        check_read(16'h00F1, 8'hFF);

        write_byte(16'h00F1, 8'h00);
        check_read(16'h00F0, 8'hA5);

        check_read(16'h0100, 8'h00);

        $display("MEMORY BUS TEST PASSED");
        $finish;
    end

endmodule